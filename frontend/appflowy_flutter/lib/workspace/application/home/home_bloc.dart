import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart'
    show WorkspaceLatestPB;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(WorkspaceLatestPB workspaceSetting)
      : _workspaceListener = FolderListener(
          workspaceId: workspaceSetting.workspaceId,
        ),
        super(HomeState.initial(workspaceSetting)) {
    _dispatch(workspaceSetting);
  }

  final FolderListener _workspaceListener;

  @override
  Future<void> close() async {
    await _workspaceListener.stop();
    return super.close();
  }

  void _dispatch(WorkspaceLatestPB workspaceSetting) {
    on<HomeEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            print('HomeBloc initial event');
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!isClosed) {
                add(HomeEvent.didReceiveWorkspaceSetting(workspaceSetting));
              }
            });

            _workspaceListener.start(
              onLatestUpdated: (result) {
                result.fold(
                  (latest) {
                    add(HomeEvent.didReceiveWorkspaceSetting(latest));
                  },
                  (r) => Log.error(r),
                );
              },
            );
          },
          showLoading: (e) async {
            emit(state.copyWith(isLoading: e.isLoading));
          },
          didReceiveWorkspaceSetting: (_DidReceiveWorkspaceSetting value) async {
            // the latest view is shared across all the members of the workspace.
            print('HomeBloc: Received workspace setting for workspace ${value.setting.workspaceId}');
            print('HomeBloc: hasLatestView = ${value.setting.hasLatestView()}');

            final latestView = value.setting.hasLatestView()
                ? value.setting.latestView
                : state.latestView;
                
            print('HomeBloc: latestView = ${latestView?.name} (id: ${latestView?.id}, isSpace: ${latestView?.isSpace})');

            ViewPB? validLatestView;
            if (latestView != null) {
              // Prefer non-space views, but allow space views if they're the only option
              // This prevents black screen when new workspace only has space-type default views
              if (!latestView.isSpace) {
                validLatestView = latestView;
              } else {
                // If it's a space view, only use it if we don't have a current valid view
                // This ensures we show something rather than a black screen
                validLatestView = state.latestView ?? latestView;
              }
            } else {
              // If no latest view exists (new workspace), try to find and set a default view
              print('No latest view found, attempting to find default view for new workspace');
              try {
                // Get current user profile to get userId
                final userResult = await UserBackendService.getCurrentUserProfile();
                final userProfile = userResult.fold((user) => user, (error) => null);
                
                if (userProfile == null) {
                  Log.error('Failed to get user profile');
                  return;
                }
                
                final workspaceService = WorkspaceService(
                  workspaceId: value.setting.workspaceId,
                  userId: userProfile.id,
                );
                
                // Try to get public views first (these are usually the main documents)
                final publicViewsResult = await workspaceService.getPublicViews();
                final publicViews = publicViewsResult.fold(
                  (views) => views,
                  (error) {
                    Log.error('Failed to get public views: $error');
                    return <ViewPB>[];
                  },
                );
                
                // Find the first non-space view or use any view if no non-space view exists
                ViewPB? defaultView;
                if (publicViews.isNotEmpty) {
                  // Prefer non-space views
                  defaultView = publicViews.firstWhere(
                    (view) => !view.isSpace,
                    orElse: () => publicViews.first, // Use first view if all are spaces
                  );
                  
                  print('Found default view: ${defaultView.name} (id: ${defaultView.id}, isSpace: ${defaultView.isSpace})');
                  validLatestView = defaultView;
                  
                  // Set this view as the latest view in the backend
                  FolderEventSetLatestView(ViewIdPB(value: defaultView.id)).send();
                }
              } catch (e) {
                Log.error('Error finding default view for new workspace: $e');
              }
            }
            
            print('HomeBloc: Final validLatestView = ${validLatestView?.name} (id: ${validLatestView?.id})');
            
            // If we still don't have a valid view, ensure TabsBloc shows homepage
            if (validLatestView == null) {
              print('HomeBloc: No valid view found, TabsBloc should show homepage for blank plugin');
            }
            
            emit(
              state.copyWith(
                workspaceSetting: value.setting,
                latestView: validLatestView,
              ),
            );
          },
        );
      },
    );
  }
}

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.initial() = _Initial;
  const factory HomeEvent.showLoading(bool isLoading) = _ShowLoading;
  const factory HomeEvent.didReceiveWorkspaceSetting(
    WorkspaceLatestPB setting,
  ) = _DidReceiveWorkspaceSetting;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required WorkspaceLatestPB workspaceSetting,
    ViewPB? latestView,
  }) = _HomeState;

  factory HomeState.initial(WorkspaceLatestPB workspaceSetting) => HomeState(
        isLoading: false,
        workspaceSetting: workspaceSetting,
      );
}
