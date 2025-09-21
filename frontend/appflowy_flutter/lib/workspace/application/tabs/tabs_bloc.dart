import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/expand_views.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/plugins/homepage/homepage.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tabs_bloc.freezed.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> {
  TabsBloc() : super(TabsState()) {
    menuSharedState = getIt<MenuSharedState>();
    _recentService = getIt<CachedRecentService>();
    _dispatch();
  }

  late final MenuSharedState menuSharedState;
  late final CachedRecentService _recentService;

  @override
  Future<void> close() {
    state.dispose();
    return super.close();
  }

  void _dispatch() {
    on<TabsEvent>(
      (event, emit) async {
        event.when(
          selectTab: (int index) {
            if (index != state.currentIndex &&
                index >= 0 &&
                index < state.pages) {
              emit(state.copyWith(currentIndex: index));
              _setLatestOpenView();
            }
          },
          moveTab: () {},
          closeTab: (String pluginId) {
            final pm = state._pageManagers
                .firstWhereOrNull((pm) => pm.plugin.id == pluginId);
            if (pm?.isPinned == true) {
              return;
            }

            emit(state.closeView(pluginId));
            _setLatestOpenView();
          },
          closeCurrentTab: () {
            if (state.currentPageManager.isPinned) {
              return;
            }

            emit(state.closeView(state.currentPageManager.plugin.id));
            _setLatestOpenView();
          },
          openTab: (Plugin plugin, ViewPB view) {
            state.currentPageManager
              ..hideSecondaryPlugin()
              ..setSecondaryPlugin(BlankPagePlugin());
            emit(state.openView(plugin));
            _setLatestOpenView(view);
          },
          openPlugin: (Plugin plugin, ViewPB? view, bool setLatest) {
            state.currentPageManager
              ..hideSecondaryPlugin()
              ..setSecondaryPlugin(BlankPagePlugin());
            
            final newState = state.openPlugin(plugin: plugin, setLatest: setLatest);
            emit(newState);
            if (setLatest) {
              // the space view should be filtered out.
              if (view != null && view.isSpace) {
                return;
              }
              _setLatestOpenView(view);
              if (view != null) _expandAncestors(view);
            }
          },
          closeOtherTabs: (String pluginId) {
            final pageManagers = [
              ...state._pageManagers
                  .where((pm) => pm.plugin.id == pluginId || pm.isPinned),
            ];

            int newIndex;
            if (state.currentPageManager.isPinned) {
              // Retain current index if it's already pinned
              newIndex = state.currentIndex;
            } else {
              final pm = state._pageManagers
                  .firstWhereOrNull((pm) => pm.plugin.id == pluginId);
              newIndex = pm != null ? pageManagers.indexOf(pm) : 0;
            }

            emit(
              state.copyWith(
                currentIndex: newIndex,
                pageManagers: pageManagers,
              ),
            );

            _setLatestOpenView();
          },
          togglePin: (String pluginId) {
            final pm = state._pageManagers
                .firstWhereOrNull((pm) => pm.plugin.id == pluginId);
            if (pm != null) {
              final index = state._pageManagers.indexOf(pm);

              int newIndex = state.currentIndex;
              if (pm.isPinned) {
                // Unpinning logic
                final indexOfFirstUnpinnedTab =
                    state._pageManagers.indexWhere((tab) => !tab.isPinned);

                // Determine the correct insertion point
                final newUnpinnedIndex = indexOfFirstUnpinnedTab != -1
                    ? indexOfFirstUnpinnedTab // Insert before the first unpinned tab
                    : state._pageManagers
                        .length; // Append at the end if no unpinned tabs exist

                state._pageManagers.removeAt(index);

                final adjustedUnpinnedIndex = newUnpinnedIndex > index
                    ? newUnpinnedIndex - 1
                    : newUnpinnedIndex;

                state._pageManagers.insert(adjustedUnpinnedIndex, pm);
                newIndex = _adjustCurrentIndex(
                  currentIndex: state.currentIndex,
                  tabIndex: index,
                  newIndex: adjustedUnpinnedIndex,
                );
              } else {
                // Pinning logic
                final indexOfLastPinnedTab =
                    state._pageManagers.lastIndexWhere((tab) => tab.isPinned);
                final newPinnedIndex = indexOfLastPinnedTab + 1;

                state._pageManagers.removeAt(index);

                final adjustedPinnedIndex = newPinnedIndex > index
                    ? newPinnedIndex - 1
                    : newPinnedIndex;

                state._pageManagers.insert(adjustedPinnedIndex, pm);
                newIndex = _adjustCurrentIndex(
                  currentIndex: state.currentIndex,
                  tabIndex: index,
                  newIndex: adjustedPinnedIndex,
                );
              }

              pm.isPinned = !pm.isPinned;

              emit(
                state.copyWith(
                  currentIndex: newIndex,
                  pageManagers: [...state._pageManagers],
                ),
              );
            }
          },
          openSecondaryPlugin: (plugin, view) {
            state.currentPageManager
              ..setSecondaryPlugin(plugin)
              ..showSecondaryPlugin();
          },
          closeSecondaryPlugin: () {
            final pageManager = state.currentPageManager;
            pageManager.hideSecondaryPlugin();
          },
          expandSecondaryPlugin: () {
            final pageManager = state.currentPageManager;
            pageManager
              ..hideSecondaryPlugin()
              ..expandSecondaryPlugin();
            _setLatestOpenView();
          },
          switchWorkspace: (workspaceId) async {
            Log.info('[TABS_SWITCH] 🚀 Starting workspace switch process');
            Log.info('[TABS_SWITCH] 📝 Target workspace ID: $workspaceId');
            Log.info('[TABS_SWITCH] 📝 Current state pages: ${state.pages}');
            Log.info('[TABS_SWITCH] 📝 Current index: ${state.currentIndex}');
            
            // 🔧 FIX: Add state validation to prevent race conditions
            if (workspaceId.isEmpty) {
              Log.error('[TABS_SWITCH] ❌ Invalid workspace ID, aborting switch');
              return;
            }
            
            try {
              // Close ALL non-pinned tabs first to clean up previous workspace state
              final pagesToClose = state._pageManagers
                  .where((pm) => !pm.isPinned)
                  .toList();

              Log.info('[TABS_SWITCH] 🗑️ Closing ${pagesToClose.length} non-pinned tabs');
              for (final pm in pagesToClose) {
                Log.info('[TABS_SWITCH] 📝 Closing tab: ${pm.plugin.runtimeType}');
              }

              // 创建一个干净的新状态来避免混乱
              TabsState newState = TabsState();
              Log.info('[TABS_SWITCH] 🔄 Created clean new TabsState');
              
              // 保留固定的标签页
              final pinnedPageManagers = state._pageManagers
                  .where((pm) => pm.isPinned)
                  .toList();
              
              Log.info('[TABS_SWITCH] 📌 Found ${pinnedPageManagers.length} pinned tabs to preserve');
              for (final pm in pinnedPageManagers) {
                Log.info('[TABS_SWITCH] 📝 Preserving pinned tab: ${pm.plugin.runtimeType}');
                newState = newState.openView(pm.plugin);
              }
              
              // 总是添加主页作为默认页面
              Log.info('[TABS_SWITCH] 🏠 Adding homepage as default tab');
              newState = newState.openPlugin(plugin: HomePagePlugin(), setLatest: false);
              
              // 🔧 FIX: Ensure valid index and state consistency
              if (newState._pageManagers.isNotEmpty) {
                final validIndex = newState._pageManagers.length - 1; // 选择主页
                Log.info('[TABS_SWITCH] 📍 Setting current index to: $validIndex (homepage)');
                newState = newState.copyWith(currentIndex: validIndex);
              } else {
                Log.warn('[TABS_SWITCH] ⚠️ No page managers found in new state!');
                // Fallback: create a minimal state with homepage
                newState = TabsState().openPlugin(plugin: HomePagePlugin(), setLatest: false);
                newState = newState.copyWith(currentIndex: 0);
                Log.info('[TABS_SWITCH] 🔧 Created fallback state with homepage');
              }
              
              Log.info('[TABS_SWITCH] 🔄 About to emit new state');
              Log.info('[TABS_SWITCH] 📝 New state pages: ${newState._pageManagers.length}');
              Log.info('[TABS_SWITCH] 📝 New state current index: ${newState.currentIndex}');
              
              emit(newState);
              
              Log.info('[TABS_SWITCH] ✅ New state emitted successfully');
              
              // 🔧 NEW FIX: Notify HomeBloc about workspace switch
              Log.info('[TABS_SWITCH] 🔔 Notifying HomeBloc about workspace switch');
              try {
                // 🔧 CRITICAL FIX: Force workspace refresh via backend
                // This will trigger all workspace listeners including HomeBloc
                Log.info('[TABS_SWITCH] 🚀 Triggering workspace refresh to notify all listeners');
                
                // Read the current workspace to trigger all workspace listeners
                final readResult = await FolderEventReadCurrentWorkspace().send();
                readResult.fold(
                  (workspace) {
                    Log.info('[TABS_SWITCH] ✅ Current workspace read successfully: ${workspace.name}');
                    Log.info('[TABS_SWITCH] 📝 Workspace ID: ${workspace.id}');
                    Log.info('[TABS_SWITCH] 📝 This should trigger HomeBloc workspace listeners');
                  },
                  (error) {
                    Log.error('[TABS_SWITCH] ❌ Failed to read current workspace: $error');
                  },
                );
                
                // Also try to get workspace settings to trigger more listeners
                final settingsResult = await FolderEventGetCurrentWorkspaceSetting().send();
                settingsResult.fold(
                  (settings) {
                    Log.info('[TABS_SWITCH] ✅ Workspace settings retrieved successfully');
                    Log.info('[TABS_SWITCH] 📝 Latest view: ${settings.latestView.name}');
                  },
                  (error) {
                    Log.error('[TABS_SWITCH] ❌ Failed to get workspace settings: $error');
                  },
                );
                
                Log.info('[TABS_SWITCH] ✅ Workspace refresh completed - all listeners should be notified');
              } catch (e) {
                Log.error('[TABS_SWITCH] ❌ Failed to refresh workspace: $e');
              }
              
              Log.info('[TABS_SWITCH] ✅ Workspace switch process completed');
              
            } catch (e, stackTrace) {
              Log.error('[TABS_SWITCH] ❌ Error during workspace switch: $e');
              Log.error('[TABS_SWITCH] ❌ Stack trace: $stackTrace');
              
              // Fallback: emit a safe minimal state
              try {
                final fallbackState = TabsState().openPlugin(plugin: HomePagePlugin(), setLatest: false);
                emit(fallbackState.copyWith(currentIndex: 0));
                Log.info('[TABS_SWITCH] 🔧 Emitted fallback state after error');
              } catch (fallbackError) {
                Log.error('[TABS_SWITCH] ❌ Fallback also failed: $fallbackError');
              }
            }

          },
          initial: () {
            // 在应用初始化时，检查当前打开的视图并添加到最近访问
            final pageManager = state.currentPageManager;
            final notifier = pageManager.plugin.notifier;
            if (notifier is ViewPluginNotifier && !notifier.view.isSpace) {
              _addToRecentViews(notifier.view.id);
            }
          },
        );
      },
    );
  }

  void _setLatestOpenView([ViewPB? view]) {
    ViewPB? targetView = view;
    
    if (targetView != null) {
      menuSharedState.latestOpenView = targetView;
    } else {
      final pageManager = state.currentPageManager;
      final notifier = pageManager.plugin.notifier;
      if (notifier is ViewPluginNotifier &&
          menuSharedState.latestOpenView?.id != notifier.view.id) {
        targetView = notifier.view;
        menuSharedState.latestOpenView = targetView;
      }
    }
    
    // 自动添加到最近访问列表（过滤掉空间视图）
    if (targetView != null && !targetView.isSpace) {
      _addToRecentViews(targetView.id);
    }
  }

  Future<void> _expandAncestors(ViewPB view) async {
    final viewExpanderRegistry = getIt.get<ViewExpanderRegistry>();
    if (viewExpanderRegistry.isViewExpanded(view.parentViewId)) return;
    final value = await getIt<KeyValueStorage>().get(KVKeys.expandedViews);
    try {
      final Map expandedViews = value == null ? {} : jsonDecode(value);
      final List<String> ancestors =
          await ViewBackendService.getViewAncestors(view.id)
              .fold((s) => s.items.map((e) => e.id).toList(), (f) => []);
      ViewExpander? viewExpander;
      
      // Get all ancestor views to check if they are spaces
      final List<ViewPB> ancestorViews = await ViewBackendService.getViewAncestors(view.id)
          .fold((s) => s.items, (f) => <ViewPB>[]);
      
      for (int i = 0; i < ancestors.length; i++) {
        final id = ancestors[i];
        final ancestorView = i < ancestorViews.length ? ancestorViews[i] : null;
        
        // For space views, only expand if they were already explicitly expanded by user
        if (ancestorView != null && ancestorView.isSpace) {
          // Only set to true if it was already true (user previously expanded it)
          if (expandedViews[id] == true) {
            expandedViews[id] = true;
          }
          // Don't force expand spaces that haven't been explicitly expanded
        } else {
          // For non-space ancestors, expand as usual
          expandedViews[id] = true;
        }
        
        final expander = viewExpanderRegistry.getExpander(id);
        if (expander == null) continue;
        if (!expander.isViewExpanded && viewExpander == null) {
          viewExpander = expander;
        }
      }
      await getIt<KeyValueStorage>()
          .set(KVKeys.expandedViews, jsonEncode(expandedViews));
      viewExpander?.expand();
    } catch (e) {
      Log.error('expandAncestors error', e);
    }
  }

  int _adjustCurrentIndex({
    required int currentIndex,
    required int tabIndex,
    required int newIndex,
  }) {
    if (tabIndex < currentIndex && newIndex >= currentIndex) {
      return currentIndex - 1; // Tab moved forward, shift currentIndex back
    } else if (tabIndex > currentIndex && newIndex <= currentIndex) {
      return currentIndex + 1; // Tab moved backward, shift currentIndex forward
    } else if (tabIndex == currentIndex) {
      return newIndex; // Tab is the current tab, update to newIndex
    }

    return currentIndex;
  }

  /// Adds a [TabsEvent.openTab] event for the provided [ViewPB]
  void openTab(ViewPB view) =>
      add(TabsEvent.openTab(plugin: view.plugin(), view: view));

  /// Adds a [TabsEvent.openPlugin] event for the provided [ViewPB]
  void openPlugin(
    ViewPB view, {
    Map<String, dynamic> arguments = const {},
  }) {
    add(
      TabsEvent.openPlugin(
        plugin: view.plugin(arguments: arguments),
        view: view,
      ),
    );
  }
  
  /// 添加视图到最近访问列表的异步方法
  void _addToRecentViews(String viewId) {
    // 使用异步方式更新最近访问，避免阻塞UI
    Future.microtask(() async {
      try {
        await _recentService.updateRecentViews([viewId], true);
        Log.debug('已添加视图到最近访问: $viewId');
      } catch (e) {
        Log.error('添加视图到最近访问失败: $viewId, 错误: $e');
      }
    });
  }

}

@freezed
class TabsEvent with _$TabsEvent {
  const factory TabsEvent.moveTab() = _MoveTab;

  const factory TabsEvent.closeTab(String pluginId) = _CloseTab;

  const factory TabsEvent.closeOtherTabs(String pluginId) = _CloseOtherTabs;

  const factory TabsEvent.closeCurrentTab() = _CloseCurrentTab;

  const factory TabsEvent.selectTab(int index) = _SelectTab;

  const factory TabsEvent.togglePin(String pluginId) = _TogglePin;

  const factory TabsEvent.openTab({
    required Plugin plugin,
    required ViewPB view,
  }) = _OpenTab;

  const factory TabsEvent.openPlugin({
    required Plugin plugin,
    ViewPB? view,
    @Default(true) bool setLatest,
  }) = _OpenPlugin;

  const factory TabsEvent.openSecondaryPlugin({
    required Plugin plugin,
    ViewPB? view,
  }) = _OpenSecondaryPlugin;

  const factory TabsEvent.closeSecondaryPlugin() = _CloseSecondaryPlugin;

  const factory TabsEvent.expandSecondaryPlugin() = _ExpandSecondaryPlugin;

  const factory TabsEvent.switchWorkspace(String workspaceId) =
      _SwitchWorkspace;
      
  const factory TabsEvent.initial() = _Initial;
}

class TabsState {
  TabsState({
    this.currentIndex = 0,
    List<PageManager>? pageManagers,
  }) : _pageManagers = pageManagers ?? [PageManager()];

  final int currentIndex;
  final List<PageManager> _pageManagers;

  int get pages => _pageManagers.length;

  PageManager get currentPageManager => _pageManagers[currentIndex];

  List<PageManager> get pageManagers => _pageManagers;

  bool get isAllPinned => _pageManagers.every((pm) => pm.isPinned);

  /// This opens a new tab given a [Plugin].
  ///
  /// If the [Plugin.id] is already associated with an open tab,
  /// then it selects that tab.
  ///
  TabsState openView(Plugin plugin) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (selectExistingPlugin == null) {
      _pageManagers.add(PageManager()..setPlugin(plugin, true));

      return copyWith(
        currentIndex: pages - 1,
        pageManagers: [..._pageManagers],
      );
    }

    return selectExistingPlugin;
  }

  TabsState closeView(String pluginId) {
    // Avoid closing the only open tab
    if (_pageManagers.length == 1) {
      return this;
    }

    _pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);

    /// If currentIndex is greater than the amount of allowed indices
    /// And the current selected tab isn't the first (index 0)
    ///   as currentIndex cannot be -1
    /// Then decrease currentIndex by 1
    final newIndex = currentIndex > pages - 1 && currentIndex > 0
        ? currentIndex - 1
        : currentIndex;

    return copyWith(
      currentIndex: newIndex,
      pageManagers: [..._pageManagers],
    );
  }

  /// This opens a plugin in the current selected tab,
  /// due to how Document currently works, only one tab
  /// per plugin can currently be active.
  ///
  /// If the plugin is already open in a tab, then that tab
  /// will become selected.
  ///
  TabsState openPlugin({required Plugin plugin, bool setLatest = true}) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (selectExistingPlugin == null) {
      final pageManagers = [..._pageManagers];
      pageManagers[currentIndex].setPlugin(plugin, setLatest);

      return copyWith(pageManagers: pageManagers);
    }

    return selectExistingPlugin;
  }

  /// Checks if a [Plugin.id] is already associated with an open tab.
  /// Returns a [TabState] with new index if there is a match.
  ///
  /// If no match it returns null
  ///
  TabsState? _selectPluginIfOpen(String id) {
    final index = _pageManagers.indexWhere((pm) => pm.plugin.id == id);

    if (index == -1) {
      return null;
    }

    if (index == currentIndex) {
      return this;
    }

    return copyWith(currentIndex: index);
  }

  TabsState copyWith({
    int? currentIndex,
    List<PageManager>? pageManagers,
  }) =>
      TabsState(
        currentIndex: currentIndex ?? this.currentIndex,
        pageManagers: pageManagers ?? _pageManagers,
      );

  void dispose() {
    for (final manager in pageManagers) {
      manager.dispose();
    }
  }
}
