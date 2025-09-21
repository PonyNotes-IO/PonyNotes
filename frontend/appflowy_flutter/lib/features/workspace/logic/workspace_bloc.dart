import 'dart:async';

import 'package:appflowy/features/workspace/data/repositories/workspace_repository.dart';
import 'package:appflowy/features/workspace/logic/workspace_event.dart';
import 'package:appflowy/features/workspace/logic/workspace_state.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:protobuf/protobuf.dart';

export 'workspace_event.dart';
export 'workspace_state.dart';

class _WorkspaceFetchResult {
  const _WorkspaceFetchResult({
    this.currentWorkspace,
    required this.workspaces,
    required this.shouldOpenWorkspace,
  });

  final UserWorkspacePB? currentWorkspace;
  final List<UserWorkspacePB> workspaces;
  final bool shouldOpenWorkspace;
}

class UserWorkspaceBloc extends Bloc<UserWorkspaceEvent, UserWorkspaceState> {
  UserWorkspaceBloc({
    required this.repository,
    required this.userProfile,
    this.initialWorkspaceId,
  })  : _listener = UserListener(userProfile: userProfile),
        super(UserWorkspaceState.initial(userProfile)) {
    on<WorkspaceEventInitialize>(_onInitialize);
    on<WorkspaceEventFetchWorkspaces>(_onFetchWorkspaces);
    on<WorkspaceEventCreateWorkspace>(_onCreateWorkspace);
    on<WorkspaceEventDeleteWorkspace>(_onDeleteWorkspace);
    on<WorkspaceEventOpenWorkspace>(_onOpenWorkspace);
    on<WorkspaceEventRenameWorkspace>(_onRenameWorkspace);
    on<WorkspaceEventUpdateWorkspaceIcon>(_onUpdateWorkspaceIcon);
    on<WorkspaceEventLeaveWorkspace>(_onLeaveWorkspace);
    on<WorkspaceEventFetchWorkspaceSubscriptionInfo>(
      _onFetchWorkspaceSubscriptionInfo,
    );
    on<WorkspaceEventUpdateWorkspaceSubscriptionInfo>(
      _onUpdateWorkspaceSubscriptionInfo,
    );
    on<WorkspaceEventEmitWorkspaces>(_onEmitWorkspaces);
    on<WorkspaceEventEmitUserProfile>(_onEmitUserProfile);
    on<WorkspaceEventEmitCurrentWorkspace>(_onEmitCurrentWorkspace);
  }

  final String? initialWorkspaceId;
  final WorkspaceRepository repository;
  final UserProfilePB userProfile;
  final UserListener _listener;

  @override
  Future<void> close() {
    _listener.stop();
    return super.close();
  }

  Future<void> _onInitialize(
    WorkspaceEventInitialize event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _setupListeners();
    await _initializeWorkspaces(emit);
  }

  Future<void> _onFetchWorkspaces(
    WorkspaceEventFetchWorkspaces event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await _fetchWorkspaces(
      initialWorkspaceId: event.initialWorkspaceId,
    );

    final currentWorkspace = result.currentWorkspace;
    final workspaces = result.workspaces;
    Log.info(
      'fetch workspaces: current workspace: ${currentWorkspace?.workspaceId}, workspaces: ${workspaces.map((e) => e.workspaceId)}',
    );

    emit(
      state.copyWith(
        workspaces: workspaces,
      ),
    );

    if (currentWorkspace != null &&
        currentWorkspace.workspaceId != state.currentWorkspace?.workspaceId) {
      Log.info(
        'fetch workspaces: try to open workspace: ${currentWorkspace.workspaceId}',
      );
      add(
        UserWorkspaceEvent.openWorkspace(
          workspaceId: currentWorkspace.workspaceId,
          workspaceType: currentWorkspace.workspaceType,
        ),
      );
    }
  }

  Future<void> _onCreateWorkspace(
    WorkspaceEventCreateWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.create,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final result = await repository.createWorkspace(
      name: event.name,
      workspaceType: event.workspaceType,
    );

    final workspaces = result.fold(
      (s) => [...state.workspaces, s],
      (e) => state.workspaces,
    );

    emit(
      state.copyWith(
        workspaces: _sortWorkspaces(workspaces),
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.create,
          isLoading: false,
          result: result.map((_) {}),
        ),
      ),
    );

    result
      ..onSuccess((s) {
     
        Log.info('create workspace success: $s');
        
        // DEBUG: Add comprehensive logging for new workspace creation flow
        Log.info('[WORKSPACE_CREATE] ✅ Workspace creation successful');
        Log.info('[WORKSPACE_CREATE] 📝 WorkspaceId: ${s.workspaceId}');
        Log.info('[WORKSPACE_CREATE] 📝 WorkspaceName: ${s.name}');
        Log.info('[WORKSPACE_CREATE] 📝 WorkspaceType: ${s.workspaceType}');
        Log.info('[WORKSPACE_CREATE] 🔄 About to trigger workspace switch...');
        
        // 🔧 FIX: Immediate workspace switch for better UX
        Log.info('[WORKSPACE_CREATE] 🚀 Triggering immediate workspace switch');
        
        // 🔧 CRITICAL FIX: Force immediate workspace switch without waiting for async openWorkspace
        // This ensures the UI switches immediately after workspace creation
        try {
          // 1. Update current workspace immediately
          emit(state.copyWith(currentWorkspace: s));
          Log.info('[WORKSPACE_CREATE] ✅ Current workspace updated immediately');
          
          // 2. Force TabsBloc to switch
          final tabsBloc = getIt<TabsBloc>();
          tabsBloc.add(TabsEvent.switchWorkspace(s.workspaceId));
          Log.info('[WORKSPACE_CREATE] ✅ TabsBloc switch event dispatched');
          
          // 3. Still trigger the full openWorkspace process in background for completeness
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: s.workspaceId,
              workspaceType: s.workspaceType,
            ),
          );
          Log.info('[WORKSPACE_CREATE] ✅ Background openWorkspace event dispatched');
        } catch (e, stackTrace) {
          Log.error('[WORKSPACE_CREATE] ❌ Failed to force immediate switch: $e');
          Log.error('[WORKSPACE_CREATE] ❌ Stack trace: $stackTrace');
          
          // Fallback to original logic
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: s.workspaceId,
              workspaceType: s.workspaceType,
            ),
          );
        }
        
      })
      ..onFailure((f) {
        Log.error('create workspace error: $f');
        print('UserWorkspaceBloc: Failed to create workspace: $f');
      });
  }

  Future<void> _onDeleteWorkspace(
    WorkspaceEventDeleteWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    Log.info('try to delete workspace: ${event.workspaceId}');
    emit(
      state.copyWith(
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.delete,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final remoteWorkspaces = await _fetchWorkspaces().then(
      (value) => value.workspaces,
    );

    if (state.workspaces.length <= 1 || remoteWorkspaces.length <= 1) {
      final result = FlowyResult.failure(
        FlowyError(
          code: ErrorCode.Internal,
          msg: LocaleKeys.workspace_cannotDeleteTheOnlyWorkspace.tr(),
        ),
      );
      return emit(
        state.copyWith(
          actionResult: WorkspaceActionResult(
            actionType: WorkspaceActionType.delete,
            result: result,
            isLoading: false,
          ),
        ),
      );
    }

    final result = await repository.deleteWorkspace(
      workspaceId: event.workspaceId,
    );
    final workspacesResult = await _fetchWorkspaces();
    final workspaces = workspacesResult.workspaces;
    final containsDeletedWorkspace =
        _findWorkspaceById(event.workspaceId, workspaces) != null;

    result
      ..onSuccess((_) {
        Log.info('delete workspace success: ${event.workspaceId}');
        final firstWorkspace = workspaces.firstOrNull;
        assert(
          firstWorkspace != null,
          'the first workspace must not be null',
        );
        if (state.currentWorkspace?.workspaceId == event.workspaceId &&
            firstWorkspace != null) {
          Log.info(
            'delete workspace: open the first workspace: ${firstWorkspace.workspaceId}',
          );
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: firstWorkspace.workspaceId,
              workspaceType: firstWorkspace.workspaceType,
            ),
          );
        }
      })
      ..onFailure((f) {
        Log.error('delete workspace error: $f');
        if (!containsDeletedWorkspace && workspaces.isNotEmpty) {
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: workspaces.first.workspaceId,
              workspaceType: workspaces.first.workspaceType,
            ),
          );
        }
      });

    emit(
      state.copyWith(
        workspaces: workspaces,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.delete,
          result: result,
          isLoading: false,
        ),
      ),
    );
  }

  Future<void> _onOpenWorkspace(
    WorkspaceEventOpenWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    // DEBUG: Comprehensive logging for workspace opening
    Log.info('[WORKSPACE_OPEN] 🚀 Starting workspace open process');
    Log.info('[WORKSPACE_OPEN] 📝 Target WorkspaceId: ${event.workspaceId}');
    Log.info('[WORKSPACE_OPEN] 📝 Target WorkspaceType: ${event.workspaceType}');
    Log.info('[WORKSPACE_OPEN] 📝 Current WorkspaceId: ${state.currentWorkspace?.workspaceId}');
    Log.info('[WORKSPACE_OPEN] 📝 Current UserProfile: ${state.userProfile.id}');
    
    emit(
      state.copyWith(
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.open,
          isLoading: true,
          result: null,
        ),
      ),
    );

    Log.info('[WORKSPACE_OPEN] 🔄 Calling repository.openWorkspace...');
    final result = await repository.openWorkspace(
      workspaceId: event.workspaceId,
      workspaceType: event.workspaceType,
    );
    
    Log.info('[WORKSPACE_OPEN] ✅ Repository.openWorkspace completed');
    Log.info('[WORKSPACE_OPEN] 📊 Result type: ${result.isSuccess ? "Success" : "Failure"}');

    final currentWorkspace = result.fold(
      (s) => _findWorkspaceById(event.workspaceId),
      (e) => state.currentWorkspace,
    );

    // 🔧 CRITICAL FIX: Update state FIRST before processing callbacks
    Log.info('[WORKSPACE_OPEN] 🔄 Emitting workspace state update...');
    Log.info('[WORKSPACE_OPEN] 📝 Setting currentWorkspace: ${currentWorkspace?.workspaceId}');
    emit(
      state.copyWith(
        currentWorkspace: currentWorkspace,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.open,
          isLoading: false,
          result: result,
        ),
      ),
    );

    result
      ..onSuccess((s) {
        Log.info('[WORKSPACE_OPEN] 🎉 Repository success callback triggered');
        Log.info('[WORKSPACE_OPEN] 📝 Success result received');
        Log.info('[WORKSPACE_OPEN] 📝 Current workspace found: ${currentWorkspace != null}');
        if (currentWorkspace != null) {
          Log.info('[WORKSPACE_OPEN] 📝 Current workspace name: ${currentWorkspace.name}');
          Log.info('[WORKSPACE_OPEN] 📝 Current workspace ID: ${currentWorkspace.workspaceId}');
        }
        
        // Trigger tabs switch immediately since state is already updated
        Log.info('[WORKSPACE_OPEN] 🔄 Triggering immediate TabsBloc.switchWorkspace');
        Log.info('[WORKSPACE_OPEN] 📝 Switching to workspace: ${event.workspaceId}');
        
        // 🔧 DEBUG: Add more detailed logging for TabsBloc interaction
        try {
          final tabsBloc = getIt<TabsBloc>();
          Log.info('[WORKSPACE_OPEN] 📝 TabsBloc instance retrieved successfully');
          Log.info('[WORKSPACE_OPEN] 📝 TabsBloc current state: ${tabsBloc.state}');
          
          tabsBloc.add(TabsEvent.switchWorkspace(event.workspaceId));
          Log.info('[WORKSPACE_OPEN] ✅ TabsBloc.switchWorkspace event dispatched successfully');
        } catch (e, stackTrace) {
          Log.error('[WORKSPACE_OPEN] ❌ Failed to dispatch TabsBloc.switchWorkspace: $e');
          Log.error('[WORKSPACE_OPEN] ❌ Stack trace: $stackTrace');
        }
        
        // Force expand the menu for new workspaces to ensure UI is visible
        // Note: HomeSettingBloc will be handled by the UI layer directly
        // since it requires context-specific parameters and is not globally registered

        // Finally, fetch subscription info (non-critical for UI)
        add(
          UserWorkspaceEvent.fetchWorkspaceSubscriptionInfo(
            workspaceId: event.workspaceId,
          ),
        );
      })
      ..onFailure((f) {
        Log.error('[WORKSPACE_OPEN] ❌ Repository failure callback triggered');
        Log.error('[WORKSPACE_OPEN] 📝 Error details: $f');
        Log.error('[WORKSPACE_OPEN] 📝 Error code: ${f.code}');
        Log.error('[WORKSPACE_OPEN] 📝 Error message: ${f.msg}');
      });
    
    Log.info('[WORKSPACE_OPEN] ✅ Workspace open process completed');

    getIt<ReminderBloc>().add(
      ReminderEvent.started(),
    );
  }

  Future<void> _onRenameWorkspace(
    WorkspaceEventRenameWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await repository.renameWorkspace(
      workspaceId: event.workspaceId,
      name: event.name,
    );

    final workspaces = result.fold(
      (s) => _updateWorkspaceInList(event.workspaceId, (workspace) {
        workspace.freeze();
        return workspace.rebuild((p0) {
          p0.name = event.name;
        });
      }),
      (f) => state.workspaces,
    );

    final currentWorkspace = _findWorkspaceById(
      state.currentWorkspace?.workspaceId ?? '',
      workspaces,
    );

    Log.info('rename workspace: ${event.workspaceId}, name: ${event.name}');

    result.onFailure((f) {
      Log.error('rename workspace error: $f');
    });

    emit(
      state.copyWith(
        workspaces: workspaces,
        currentWorkspace: currentWorkspace,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.rename,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _onUpdateWorkspaceIcon(
    WorkspaceEventUpdateWorkspaceIcon event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final workspace = _findWorkspaceById(event.workspaceId);
    if (workspace == null) {
      Log.error('workspace not found: ${event.workspaceId}');
      return;
    }

    if (event.icon == workspace.icon) {
      Log.info('ignore same icon update');
      return;
    }

    final result = await repository.updateWorkspaceIcon(
      workspaceId: event.workspaceId,
      icon: event.icon,
    );

    final workspaces = result.fold(
      (s) => _updateWorkspaceInList(event.workspaceId, (workspace) {
        workspace.freeze();
        return workspace.rebuild((p0) {
          p0.icon = event.icon;
        });
      }),
      (f) => state.workspaces,
    );

    final currentWorkspace = _findWorkspaceById(
      state.currentWorkspace?.workspaceId ?? '',
      workspaces,
    );

    Log.info(
      'update workspace icon: ${event.workspaceId}, icon: ${event.icon}',
    );

    result.onFailure((f) {
      Log.error('update workspace icon error: $f');
    });

    emit(
      state.copyWith(
        workspaces: workspaces,
        currentWorkspace: currentWorkspace,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.updateIcon,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _onLeaveWorkspace(
    WorkspaceEventLeaveWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final result = await repository.leaveWorkspace(
      workspaceId: event.workspaceId,
    );

    final workspaces = result.fold(
      (s) => state.workspaces
          .where((e) => e.workspaceId != event.workspaceId)
          .toList(),
      (e) => state.workspaces,
    );

    result
      ..onSuccess((_) {
        Log.info('leave workspace success: ${event.workspaceId}');
        if (state.currentWorkspace?.workspaceId == event.workspaceId &&
            workspaces.isNotEmpty) {
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: workspaces.first.workspaceId,
              workspaceType: workspaces.first.workspaceType,
            ),
          );
        }
      })
      ..onFailure((f) {
        Log.error('leave workspace error: $f');
      });

    emit(
      state.copyWith(
        workspaces: _sortWorkspaces(workspaces),
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.leave,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _onFetchWorkspaceSubscriptionInfo(
    WorkspaceEventFetchWorkspaceSubscriptionInfo event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    final enabled = await repository.isBillingEnabled();
    // If billing is not enabled, we don't need to fetch the workspace subscription info
    if (!enabled) {
      return;
    }

    unawaited(
      repository
          .getWorkspaceSubscriptionInfo(
        workspaceId: event.workspaceId,
      )
          .fold(
        (workspaceSubscriptionInfo) {
          if (isClosed) {
            return;
          }

          if (state.currentWorkspace?.workspaceId != event.workspaceId) {
            return;
          }

          Log.debug(
            'fetch workspace subscription info: ${event.workspaceId}, $workspaceSubscriptionInfo',
          );

          add(
            UserWorkspaceEvent.updateWorkspaceSubscriptionInfo(
              workspaceId: event.workspaceId,
              subscriptionInfo: workspaceSubscriptionInfo,
            ),
          );
        },
        (e) => Log.error('fetch workspace subscription info error: $e'),
      ),
    );
  }

  Future<void> _onUpdateWorkspaceSubscriptionInfo(
    WorkspaceEventUpdateWorkspaceSubscriptionInfo event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    emit(
      state.copyWith(workspaceSubscriptionInfo: event.subscriptionInfo),
    );
  }

  Future<void> _onEmitWorkspaces(
    WorkspaceEventEmitWorkspaces event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    emit(
      state.copyWith(
        workspaces: _sortWorkspaces(event.workspaces),
      ),
    );
  }

  Future<void> _onEmitUserProfile(
    WorkspaceEventEmitUserProfile event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    emit(
      state.copyWith(userProfile: event.userProfile),
    );
  }

  Future<void> _onEmitCurrentWorkspace(
    WorkspaceEventEmitCurrentWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    emit(
      state.copyWith(currentWorkspace: event.workspace),
    );
  }

  Future<void> _setupListeners() async {
    _listener.start(
      onProfileUpdated: (result) {
        if (!isClosed) {
          result.fold(
            (newProfile) => add(
              UserWorkspaceEvent.emitUserProfile(userProfile: newProfile),
            ),
            (error) => Log.error("Failed to get user profile: $error"),
          );
        }
      },
      onUserWorkspaceListUpdated: (workspaces) {
        if (!isClosed) {
          add(
            UserWorkspaceEvent.emitWorkspaces(
              workspaces: _sortWorkspaces(workspaces.items),
            ),
          );
        }
      },
      onUserWorkspaceUpdated: (workspace) {
        if (!isClosed) {
          if (state.currentWorkspace?.workspaceId == workspace.workspaceId) {
            add(UserWorkspaceEvent.emitCurrentWorkspace(workspace: workspace));
          }
        }
      },
    );
  }

  Future<void> _initializeWorkspaces(Emitter<UserWorkspaceState> emit) async {
    final result = await _fetchWorkspaces(
      initialWorkspaceId: initialWorkspaceId,
    );
    final currentWorkspace = result.currentWorkspace;
    final workspaces = result.workspaces;
    final isCollabWorkspaceOn =
        state.userProfile.userAuthType == AuthTypePB.Server &&
            FeatureFlag.collaborativeWorkspace.isOn;

    Log.info(
      'init workspace, current workspace: ${currentWorkspace?.workspaceId}, '
      'workspaces: ${workspaces.map((e) => e.workspaceId)}, isCollabWorkspaceOn: $isCollabWorkspaceOn',
    );

    if (currentWorkspace != null) {
      add(
        UserWorkspaceEvent.fetchWorkspaceSubscriptionInfo(
          workspaceId: currentWorkspace.workspaceId,
        ),
      );
    }

    if (currentWorkspace != null && result.shouldOpenWorkspace == true) {
      Log.info('init open workspace: ${currentWorkspace.workspaceId}');
      await repository.openWorkspace(
        workspaceId: currentWorkspace.workspaceId,
        workspaceType: currentWorkspace.workspaceType,
      );
    }

    emit(
      state.copyWith(
        currentWorkspace: currentWorkspace,
        workspaces: workspaces,
        isCollabWorkspaceOn: isCollabWorkspaceOn,
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.none,
          isLoading: false,
          result: null,
        ),
      ),
    );
  }

  // Helper methods
  List<UserWorkspacePB> _sortWorkspaces(List<UserWorkspacePB> workspaces) {
    final sorted = [...workspaces];
    sorted.sort(
      (a, b) => a.createdAtTimestamp.compareTo(b.createdAtTimestamp),
    );
    return sorted;
  }

  UserWorkspacePB? _findWorkspaceById(
    String id, [
    List<UserWorkspacePB>? workspacesList,
  ]) {
    final workspaces = workspacesList ?? state.workspaces;
    return workspaces.firstWhereOrNull((e) => e.workspaceId == id);
  }

  List<UserWorkspacePB> _updateWorkspaceInList(
    String workspaceId,
    UserWorkspacePB Function(UserWorkspacePB workspace) updater,
  ) {
    final workspaces = [...state.workspaces];
    final index = workspaces.indexWhere((e) => e.workspaceId == workspaceId);
    if (index != -1) {
      workspaces[index] = updater(workspaces[index]);
    }
    return workspaces;
  }

  Future<_WorkspaceFetchResult> _fetchWorkspaces({
    String? initialWorkspaceId,
  }) async {
    try {
      final currentWorkspaceResult = await repository.getCurrentWorkspace();
      final currentWorkspace = currentWorkspaceResult.fold(
        (s) => s,
        (e) => null,
      );
      final currentWorkspaceId = initialWorkspaceId ?? currentWorkspace?.id;
      final workspacesResult = await repository.getWorkspaces();
      final workspaces = workspacesResult.getOrThrow();

      if (workspaces.isEmpty && currentWorkspace != null) {
        workspaces.add(
          _convertWorkspacePBToUserWorkspace(currentWorkspace),
        );
      }

      final currentWorkspaceInList = _findWorkspaceById(
            currentWorkspaceId ?? '',
            workspaces,
          ) ??
          workspaces.firstOrNull;

      final sortedWorkspaces = _sortWorkspaces(workspaces);

      Log.info(
        'fetch workspaces: current workspace: ${currentWorkspaceInList?.workspaceId}, sorted workspaces: ${sortedWorkspaces.map((e) => '${e.name}: ${e.workspaceId}')}',
      );

      return _WorkspaceFetchResult(
        currentWorkspace: currentWorkspaceInList,
        workspaces: sortedWorkspaces,
        shouldOpenWorkspace:
            currentWorkspaceInList?.workspaceId != currentWorkspaceId,
      );
    } catch (e) {
      Log.error('fetch workspace error: $e');
      return _WorkspaceFetchResult(
        currentWorkspace: state.currentWorkspace,
        workspaces: state.workspaces,
        shouldOpenWorkspace: false,
      );
    }
  }

  UserWorkspacePB _convertWorkspacePBToUserWorkspace(WorkspacePB workspace) {
    return UserWorkspacePB.create()
      ..workspaceId = workspace.id
      ..name = workspace.name
      ..createdAtTimestamp = workspace.createTime;
  }
}
