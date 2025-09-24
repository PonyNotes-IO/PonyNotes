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
      : super(HomeState.initial(workspaceSetting)) {
    _workspaceListener = FolderListener(
      workspaceId: workspaceSetting.workspaceId,
    );
    _dispatch(workspaceSetting);
  }

  late FolderListener _workspaceListener;

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
            Log.info('[HOME_BLOC] 🚀 HomeBloc initial event triggered');
            Log.info('[HOME_BLOC] 📝 Workspace ID: ${workspaceSetting.workspaceId}');
            Log.info('[HOME_BLOC] 📝 Latest view ID: ${workspaceSetting.latestView.id}');
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!isClosed) {
                Log.info('[HOME_BLOC] ⏰ 300ms delay completed, triggering didReceiveWorkspaceSetting');
                add(HomeEvent.didReceiveWorkspaceSetting(workspaceSetting));
              } else {
                Log.warn('[HOME_BLOC] ⚠️ HomeBloc was closed before delayed event could fire');
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
            Log.info('[HOME_BLOC] 📨 Received workspace setting');
            Log.info('[HOME_BLOC] 📝 Workspace ID: ${value.setting.workspaceId}');
            Log.info('[HOME_BLOC] 📝 Latest view ID: ${value.setting.latestView.id}');
            Log.info('[HOME_BLOC] 📝 Latest view name: ${value.setting.latestView.name}');
            Log.info('[HOME_BLOC] 📊 Has latest view: ${value.setting.hasLatestView()}');

            final latestView = value.setting.hasLatestView()
                ? value.setting.latestView
                : state.latestView;
                
            Log.info('[HOME_BLOC] 📝 Resolved latest view: ${latestView?.name}');
            Log.info('[HOME_BLOC] 📝 Latest view ID: ${latestView?.id}');
            Log.info('[HOME_BLOC] 📝 Latest view isSpace: ${latestView?.isSpace}');
            Log.info('[HOME_BLOC] 📝 Current state latest view: ${state.latestView?.name}');

            ViewPB? validLatestView;
            if (latestView != null) {
              // Prefer non-space views, but allow space views if they're the only option
              // This prevents black screen when new workspace only has space-type default views
              if (!latestView.isSpace) {
                Log.info('[HOME_BLOC] ✅ Using non-space view as valid latest view');
                validLatestView = latestView;
              } else {
                // If it's a space view, only use it if we don't have a current valid view
                // This ensures we show something rather than a black screen
                validLatestView = state.latestView ?? latestView;
                Log.info('[HOME_BLOC] 🏠 Using space view as fallback: ${validLatestView.name}');
              }
            } else {
              // If no latest view exists (new workspace), try to find and set a default view
              Log.info('[HOME_BLOC] 🔍 No latest view found, attempting to find default view for new workspace');
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
            
            Log.info('[HOME_BLOC] 🎯 Final validLatestView determined');
            Log.info('[HOME_BLOC] 📝 Final view name: ${validLatestView?.name}');
            Log.info('[HOME_BLOC] 📝 Final view ID: ${validLatestView?.id}');
            Log.info('[HOME_BLOC] 📝 Final view isSpace: ${validLatestView?.isSpace}');
            
            // If we still don't have a valid view, ensure TabsBloc shows homepage
            if (validLatestView == null) {
              Log.warn('[HOME_BLOC] ⚠️ No valid view found, TabsBloc should show homepage for blank plugin');
            }
            
            Log.info('[HOME_BLOC] 🔄 About to emit final state');
            emit(
              state.copyWith(
                workspaceSetting: value.setting,
                latestView: validLatestView,
              ),
            );
            Log.info('[HOME_BLOC] ✅ Final state emitted successfully');
          },
          switchWorkspace: (_SwitchWorkspace value) async {
            Log.info('[HOME_BLOC] 🔄 Switching workspace to: ${value.workspaceId}');
            
            // Stop the current workspace listener
            await _workspaceListener.stop();
            Log.info('[HOME_BLOC] ⏹️ Old workspace listener stopped');
            
            // Create a new listener for the new workspace
            _workspaceListener = FolderListener(
              workspaceId: value.workspaceId,
            );
            Log.info('[HOME_BLOC] 🔄 New workspace listener created for: ${value.workspaceId}');
            
            // Start the new listener
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
            Log.info('[HOME_BLOC] ✅ New workspace listener started');
            
            // Request the latest workspace setting for the new workspace
            // 🔧 FIX: Add retry mechanism for folder initialization
            await _requestWorkspaceSettingWithRetry(value.workspaceId);
          },
        );
      },
    );
  }

  /// 🔧 FIX: Retry mechanism for workspace setting request
  /// This handles the "folder is not initialized" error that occurs during workspace switching
  Future<void> _requestWorkspaceSettingWithRetry(String workspaceId) async {
    const maxRetries = 10; // 增加重试次数
    const retryDelay = Duration(milliseconds: 500); // 增加重试间隔
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      Log.info('[HOME_BLOC] 🔄 Requesting workspace setting (attempt $attempt/$maxRetries)');
      
      final result = await FolderEventReadCurrentWorkspace().send();
      
      final success = result.fold(
        (workspace) {
          Log.info('[HOME_BLOC] ✅ Retrieved workspace setting for: ${workspace.id}');
          
          // 🔧 FIX: Check if BLoC is still open before emitting
          if (isClosed) {
            Log.warn('[HOME_BLOC] ⚠️ BLoC is closed, skipping state emission');
            return true;
          }
          
          final workspaceSetting = WorkspaceLatestPB()
            ..workspaceId = workspace.id
            ..latestView = ViewPB(); // Will be updated by the listener
          
          // Use add instead of emit to trigger proper event handling
          add(HomeEvent.didReceiveWorkspaceSetting(workspaceSetting));
          return true;
        },
        (error) {
          final errorMsg = error.toString();
          
          if (errorMsg.contains('folder is not initialized') && attempt < maxRetries) {
            Log.warn('[HOME_BLOC] ⏳ Folder not initialized yet (attempt $attempt/$maxRetries), retrying in ${retryDelay.inMilliseconds}ms...');
            return false; // Continue retrying
          } else {
            Log.error('[HOME_BLOC] ❌ Failed to get workspace setting: $error');
            return true; // Stop retrying on other errors or max attempts reached
          }
        },
      );
      
      if (success) {
        break;
      }
      
      // Wait before retry
      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
  }
}

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.initial() = _Initial;
  const factory HomeEvent.showLoading(bool isLoading) = _ShowLoading;
  const factory HomeEvent.didReceiveWorkspaceSetting(
    WorkspaceLatestPB setting,
  ) = _DidReceiveWorkspaceSetting;
  const factory HomeEvent.switchWorkspace(String workspaceId) = _SwitchWorkspace;
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
