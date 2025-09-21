import 'package:appflowy/features/workspace/data/repositories/rust_workspace_repository_impl.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/memory_leak_detector.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/home/home_bloc.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy/workspace/presentation/home/af_focus_manager.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar.dart';
import 'package:appflowy/workspace/presentation/widgets/edit_panel/panel_animation.dart';
import 'package:appflowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sized_context/sized_context.dart';
import 'package:styled_widget/styled_widget.dart';

import '../notifications/notification_panel.dart';
import '../notifications/notification_page.dart';
import '../widgets/edit_panel/edit_panel.dart';
import '../widgets/sidebar_resizer.dart';
import 'home_layout.dart';
import 'home_stack.dart';
import 'menu/sidebar/slider_menu_hover_trigger.dart';
import 'menu/sidebar/shared/sidebar_manager.dart';

class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({super.key});

  static const routeName = '/DesktopHomeScreen';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FolderEventGetCurrentWorkspaceSetting().send(),
        getIt<AuthService>().getUser(),
      ]),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return _buildLoading();
        }

        final workspaceLatest = snapshots.data?[0].fold(
          (workspaceLatestPB) => workspaceLatestPB as WorkspaceLatestPB,
          (error) => null,
        );

        final userProfile = snapshots.data?[1].fold(
          (userProfilePB) => userProfilePB as UserProfilePB,
          (error) => null,
        );

        // In the unlikely case either of the above is null, eg.
        // when a workspace is already open this can happen.
        if (workspaceLatest == null || userProfile == null) {
          return const WorkspaceFailedScreen();
        }

        return AFFocusManager(
          child: MultiBlocProvider(
            key: ValueKey(userProfile.id),
            providers: [
              BlocProvider.value(
                value: getIt<ReminderBloc>(),
              ),
              BlocProvider<TabsBloc>.value(value: getIt<TabsBloc>()),
              BlocProvider<HomeBloc>(
                create: (_) {
                  // 触发 TabsBloc 初始化，确保当前页面被添加到最近访问
                  getIt<TabsBloc>().add(const TabsEvent.initial());
                  return HomeBloc(workspaceLatest)..add(const HomeEvent.initial());
                },
              ),
              BlocProvider<HomeSettingBloc>(
                create: (_) => HomeSettingBloc(
                  workspaceLatest,
                  context.read<AppearanceSettingsCubit>(),
                  context.widthPx,
                )..add(const HomeSettingEvent.initial()),
              ),
              BlocProvider<FavoriteBloc>(
                create: (context) =>
                    FavoriteBloc()..add(const FavoriteEvent.initial()),
              ),
              ChangeNotifierProvider<SidebarManager>.value(
                value: getIt<SidebarManager>(),
              ),
            ],
            child: Scaffold(
              floatingActionButton: enableMemoryLeakDetect
                  ? const FloatingActionButton(
                      onPressed: dumpMemoryLeak,
                      child: Icon(Icons.memory),
                    )
                  : null,
              body: BlocListener<HomeBloc, HomeState>(
                listenWhen: (p, c) => 
                  p.latestView != c.latestView,
                listener: (context, state) async {
                  final currentPageManager =
                      context.read<TabsBloc>().state.currentPageManager;

                  Log.info('[DESKTOP_HOME] 📋 HomeBloc state changed:');
                  Log.info('[DESKTOP_HOME] 📝 latestView: ${state.latestView?.id ?? 'null'}');
                  Log.info('[DESKTOP_HOME] 📝 currentPlugin: ${currentPageManager.plugin.id} (${currentPageManager.plugin.pluginType})');

                  // If there's a new latest view, validate it exists before opening
                  if (state.latestView != null && 
                      state.latestView!.id.isNotEmpty &&
                      state.latestView!.id != currentPageManager.plugin.id) {
                    
                    // 🔧 FIX: Validate view exists before opening
                    try {
                      Log.info('[DESKTOP_HOME] 🔍 Validating view: ${state.latestView!.id}');
                      // Check if the view actually exists in the current workspace
                      final viewResult = await ViewBackendService.getView(state.latestView!.id);
                      
                      viewResult.fold(
                        (view) {
                          // View exists, safe to open
                          Log.info('[DESKTOP_HOME] ✅ View validated, opening: ${view.name} (${view.id})');
                          getIt<TabsBloc>().add(
                            TabsEvent.openPlugin(
                              plugin: view.plugin(),
                              view: view,
                            ),
                          );
                        },
                        (error) {
                          // View doesn't exist, show homepage instead
                          Log.warn('[DESKTOP_HOME] ⚠️ View not found (${error}), showing homepage instead');
                          
                          // Clear the invalid latest view from HomeBloc state
                          // This prevents repeated attempts to open non-existent views
                          
                          // Show homepage if current plugin is blank or invalid
                          if (currentPageManager.plugin.pluginType == PluginType.blank) {
                            final homePlugin = makePlugin(
                              pluginType: PluginType.homepage,
                              data: null,
                            );
                            getIt<TabsBloc>().add(
                              TabsEvent.openPlugin(plugin: homePlugin),
                            );
                          }
                        },
                      );
                    } catch (e) {
                      Log.error('[DESKTOP_HOME] ❌ Error validating view: $e');
                      
                      // Fallback to homepage on any error
                      if (currentPageManager.plugin.pluginType == PluginType.blank) {
                        final homePlugin = makePlugin(
                          pluginType: PluginType.homepage,
                          data: null,
                        );
                        getIt<TabsBloc>().add(
                          TabsEvent.openPlugin(plugin: homePlugin),
                        );
                      }
                    }
                  } else if (state.latestView == null || state.latestView!.id.isEmpty) {
                    // No valid latest view, show homepage if current plugin is blank
                    Log.info('[DESKTOP_HOME] 📝 No valid latest view, checking current plugin');
                    if (currentPageManager.plugin.pluginType == PluginType.blank) {
                      Log.info('[DESKTOP_HOME] 🏠 Opening homepage (no valid latest view)');
                      final homePlugin = makePlugin(
                        pluginType: PluginType.homepage,
                        data: null,
                      );
                      getIt<TabsBloc>().add(
                        TabsEvent.openPlugin(plugin: homePlugin),
                      );
                    }
                  } else if (currentPageManager.plugin.pluginType == PluginType.blank) {
                    // Only open homepage if current plugin is blank and no latest view
                    Log.info('[DESKTOP_HOME] 🏠 Opening homepage (blank plugin)');
                    final homePlugin = makePlugin(
                      pluginType: PluginType.homepage,
                      data: null,
                    );
                    getIt<TabsBloc>().add(
                      TabsEvent.openPlugin(plugin: homePlugin),
                    );
                  }
                },
                child: BlocBuilder<HomeSettingBloc, HomeSettingState>(
                  buildWhen: (previous, current) => previous != current,
                  builder: (context, state) => BlocProvider(
                    create: (_) => UserWorkspaceBloc(
                      userProfile: userProfile,
                      repository: RustWorkspaceRepositoryImpl(
                        userId: userProfile.id,
                      ),
                    )..add(UserWorkspaceEvent.initialize()),
                    child: BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
                      listenWhen: (previous, current) =>
                          previous.currentWorkspace != current.currentWorkspace,
                      listener: (context, state) {
                        if (!context.mounted) return;
                        final workspaceBloc =
                            context.read<UserWorkspaceBloc?>();
                        final spaceBloc = context.read<SpaceBloc?>();
                        CommandPalette.maybeOf(context)?.updateBlocs(
                          workspaceBloc: workspaceBloc,
                          spaceBloc: spaceBloc,
                        );
                        
                        // 🔧 NEW FIX: Notify HomeBloc about workspace change
                        final currentWorkspace = state.currentWorkspace;
                        if (currentWorkspace != null) {
                          Log.info('[DESKTOP_HOME] 🔔 Notifying HomeBloc about workspace change: ${currentWorkspace.workspaceId}');
                          try {
                            final homeBloc = context.read<HomeBloc?>();
                            homeBloc?.add(HomeEvent.switchWorkspace(currentWorkspace.workspaceId));
                            Log.info('[DESKTOP_HOME] ✅ HomeBloc notified successfully');
                          } catch (e) {
                            Log.error('[DESKTOP_HOME] ❌ Failed to notify HomeBloc: $e');
                          }
                        }
                      },
                      child: HomeHotKeys(
                        userProfile: userProfile,
                        child: FlowyContainer(
                          Theme.of(context).colorScheme.surface,
                          child: _buildBody(
                            context,
                            userProfile,
                            workspaceLatest,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator.adaptive());

  Widget _buildBody(
    BuildContext context,
    UserProfilePB userProfile,
    WorkspaceLatestPB workspaceSetting,
  ) {
    final layout = HomeLayout(context);
    final homeStack = HomeStack(
      layout: layout,
      delegate: DesktopHomeScreenStackAdaptor(context),
      userProfile: userProfile,
    );
    final sidebar = _buildHomeSidebar(
      context,
      layout: layout,
      userProfile: userProfile,
      workspaceSetting: workspaceSetting,
    );
    final notificationPanel = BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (previous, current) =>
          previous.isNotificationPanelCollapsed != current.isNotificationPanelCollapsed,
      builder: (context, state) {
        // 如果通知面板被折叠，显示通知页面
        if (state.isNotificationPanelCollapsed) {
          return const NotificationPage();
        }
        return const NotificationPanel();
      },
    );
    final sliderHoverTrigger = SliderMenuHoverTrigger();

    final homeMenuResizer =
        layout.showMenu ? const SidebarResizer() : const SizedBox.shrink();
    final editPanel = _buildEditPanel(context, layout: layout);

    return _layoutWidgets(
      layout: layout,
      homeStack: homeStack,
      sidebar: sidebar,
      editPanel: editPanel,
      bubble: const QuestionBubble(),
      homeMenuResizer: homeMenuResizer,
      notificationPanel: notificationPanel,
      sliderHoverTrigger: sliderHoverTrigger,
    );
  }

  Widget _buildHomeSidebar(
    BuildContext context, {
    required HomeLayout layout,
    required UserProfilePB userProfile,
    required WorkspaceLatestPB workspaceSetting,
  }) {
    final homeMenu = HomeSideBar(
      userProfile: userProfile,
      workspaceSetting: workspaceSetting,
    );
    return FocusTraversalGroup(child: RepaintBoundary(child: homeMenu));
  }

  Widget _buildEditPanel(
    BuildContext context, {
    required HomeLayout layout,
  }) {
    final homeBloc = context.read<HomeSettingBloc>();
    return BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (previous, current) =>
          previous.panelContext != current.panelContext,
      builder: (context, state) {
        final panelContext = state.panelContext;
        if (panelContext == null) {
          return const SizedBox.shrink();
        }

        return FocusTraversalGroup(
          child: RepaintBoundary(
            child: EditPanel(
              panelContext: panelContext,
              onEndEdit: () => homeBloc.add(
                const HomeSettingEvent.dismissEditPanel(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _layoutWidgets({
    required HomeLayout layout,
    required Widget sidebar,
    required Widget homeStack,
    required Widget editPanel,
    required Widget bubble,
    required Widget homeMenuResizer,
    required Widget notificationPanel,
    required Widget sliderHoverTrigger,
  }) {
    final isSliderbarShowing = layout.showMenu;
    return Consumer<SidebarManager>(
      builder: (context, sidebarManager, child) {
        print('DesktopHomeScreen: 重建界面 - 侧边栏可见: ${sidebarManager.isSidebarVisible}');
        return Stack(
          children: [
            homeStack
                .constrained(minWidth: 500)
                .positioned(
                  left: layout.homePageLOffset,
                  right: layout.homePageROffset,
                  bottom: 0,
                  top: 0,
                  animate: true,
                )
                .animate(layout.animDuration, Curves.easeOutQuad),
            bubble
                .positioned(right: 20, bottom: 16, animate: true)
                .animate(layout.animDuration, Curves.easeOut),
            editPanel
                .animatedPanelX(
                  duration: layout.animDuration.inMilliseconds * 0.001,
                  closeX: layout.editPanelWidth,
                  isClosed: !layout.showEditPanel,
                  curve: Curves.easeOutQuad,
                )
                .positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: layout.editPanelWidth,
                ),
            notificationPanel
                .animatedPanelX(
                  closeX: -layout.notificationPanelWidth,
                  isClosed: !layout.showNotificationPanel,
                  curve: Curves.easeOutQuad,
                  duration: layout.animDuration.inMilliseconds * 0.001,
                )
                .positioned(
                  left: isSliderbarShowing ? layout.menuWidth : 0,
                  top: isSliderbarShowing ? 0 : 52,
                  width: layout.notificationPanelWidth,
                  bottom: 0,
                ),
            sidebar
                .animatedPanelX(
                  closeX: -layout.menuWidth,
                  isClosed: !isSliderbarShowing,
                  curve: Curves.easeOutQuad,
                  duration: layout.animDuration.inMilliseconds * 0.001,
                )
                .positioned(left: 0, top: 0, width: layout.menuWidth, bottom: 0),
            homeMenuResizer
                .positioned(left: layout.menuWidth)
                .animate(layout.animDuration, Curves.easeOutQuad),

          ],
        );
      },
    );
  }

  Future<void> _switchToSpace(ViewPB view) async {
    final ancestors = await ViewBackendService.getViewAncestors(view.id);
    final space = ancestors.fold(
      (ancestors) =>
          ancestors.items.firstWhereOrNull((ancestor) => ancestor.isSpace),
      (error) => null,
    );
    if (space?.id != switchToSpaceNotifier.value?.id) {
      switchToSpaceNotifier.value = space;
    }
  }
}

class DesktopHomeScreenStackAdaptor extends HomeStackDelegate {
  DesktopHomeScreenStackAdaptor(this.buildContext);

  final BuildContext buildContext;

  @override
  void didDeleteStackWidget(ViewPB view, int? index) {
    ViewBackendService.getView(view.parentViewId).then(
      (result) => result.fold(
        (parentView) {
          final List<ViewPB> views = parentView.childViews;
          if (views.isNotEmpty) {
            ViewPB lastView = views.last;
            if (index != null && index != 0 && views.length > index - 1) {
              lastView = views[index - 1];
            }

            return getIt<TabsBloc>()
                .add(TabsEvent.openPlugin(plugin: lastView.plugin()));
          }

          getIt<TabsBloc>()
              .add(TabsEvent.openPlugin(plugin: BlankPagePlugin()));
        },
        (err) => Log.error(err),
      ),
    );
  }
}
