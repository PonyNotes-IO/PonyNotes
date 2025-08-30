import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/trash/application/trash_bloc.dart';
import 'package:appflowy/plugins/trash/src/trash_cell.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_manager.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class TrashPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return DatabaseTabBarViewPlugin(pluginType: pluginType, view: data);
    } else {
      // 支持无data时返回主回收站页面
      return TrashMainPlugin();
    }
  }

  @override
  String get menuName => LocaleKeys.trash_text.tr();

  @override
  FlowySvgData get icon => FlowySvgs.icon_trash_s;

  @override
  PluginType get pluginType => PluginType.trash;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

// 新增主回收站插件
class TrashMainPlugin extends Plugin {
  @override
  PluginType get pluginType => PluginType.trash;

  @override
  PluginWidgetBuilder get widgetBuilder => TrashMainWidgetBuilder();

  @override
  PluginId get id => "TrashMainStack"; // 使用固定ID，类似问AI的做法
}

class TrashMainWidgetBuilder extends PluginWidgetBuilder {
  @override
  String? get viewName => '回收站'; // 显示标题

  @override
  Widget get leftBarItem => const SizedBox.shrink(); // 不显示左侧标题

  @override
  Widget? get rightBarItem => null;

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) =>
      leftBarItem; // 显示标签栏标题

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  EdgeInsets get contentPadding => EdgeInsets.zero; // 去除所有留白

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    // 不依赖context.userProfile，避免触发GET_VIEW_PB查询
    // 直接返回回收站面板，避免视图查找错误
    return TrashMainPanel();
  }
}

// 主回收站面板骨架 - 包含侧边栏和主界面
class TrashMainPanel extends StatefulWidget {
  @override
  State<TrashMainPanel> createState() => _TrashMainPanelState();
}

class _TrashMainPanelState extends State<TrashMainPanel> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Row(
        children: [
          // 左侧回收站侧边栏
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _isSidebarExpanded ? 300 : 60,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            clipBehavior: Clip.hardEdge,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              maxWidth: _isSidebarExpanded ? 300 : 60,
              child: Column(
                children: [
                  // 顶部工具栏，包含收起/展开按钮
                  Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: ClipRect(
                      child: _isSidebarExpanded 
                        ? Row(
                            children: [
                              Expanded(
                                child: FlowyText.medium(
                                  '回收站',
                                  fontSize: FontSizes.s16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 4),
                              // 收起/展开按钮 (使用双箭头图标)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  icon: Icon(Icons.keyboard_double_arrow_left, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _isSidebarExpanded = !_isSidebarExpanded;
                                    });
                                  },
                                  tooltip: '收起侧边栏',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints.tightFor(width: 32, height: 32),
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                          )
                        : Center(
                            child: IconButton(
                              icon: Icon(Icons.keyboard_double_arrow_right, size: 22),
                              onPressed: () {
                                setState(() {
                                  _isSidebarExpanded = !_isSidebarExpanded;
                                });
                              },
                              tooltip: '展开侧边栏',
                            ),
                          ),
                    ),
                  ),
                  // 侧边栏内容
                  Expanded(
                    child: _isSidebarExpanded ? _buildExpandedSidebar() : _buildCollapsedSidebar(),
                  ),
                ],
              ),
            ),
          ),
          // 右侧主界面区域
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSidebar() {
    return TrashSidebarContent();
  }

  Widget _buildCollapsedSidebar() {
    return Column(
      children: [
        const VSpace(16),
        Expanded(
          child: Center(
            child: Icon(
              Icons.delete_outline,
              size: 24,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '回收站',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '删除的页面将显示在左侧侧边栏中',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// 回收站侧边栏内容组件
class TrashSidebarContent extends StatefulWidget {
  const TrashSidebarContent({super.key});

  @override
  State<TrashSidebarContent> createState() => _TrashSidebarContentState();
}

class _TrashSidebarContentState extends State<TrashSidebarContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: BlocBuilder<TrashBloc, TrashState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.objects.isEmpty
                    ? _buildEmptyState(context)
                    : _buildTrashList(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          Image.asset(
            'assets/images/recycleBin.png',
            width: 80,
            height: 80,
          ),
          const VSpace(16),
          FlowyText.medium(
            '回收站是空的',
            fontSize: FontSizes.s16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
          const VSpace(8),
          FlowyText.regular(
            '删除的页面将显示在这里',
            fontSize: FontSizes.s14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildTrashList(BuildContext context, TrashState state) {
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: _scrollController,
      barSize: 6.0,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.objects.length,
        itemBuilder: (context, index) {
          final object = state.objects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TrashCell(
              object: object,
              onRestore: () => showCancelAndConfirmDialog(
                context: context,
                title: LocaleKeys.trash_restorePage_title.tr(args: [object.name]),
                description: LocaleKeys.trash_restorePage_caption.tr(),
                confirmLabel: LocaleKeys.trash_restore.tr(),
                onConfirm: (_) => context
                    .read<TrashBloc>()
                    .add(TrashEvent.putback(object.id)),
              ),
              onDelete: () => showConfirmDeletionDialog(
                context: context,
                name: object.name.trim().isEmpty
                    ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
                    : object.name,
                description:
                    LocaleKeys.deletePagePrompt_deletePermanentDescription.tr(),
                onConfirm: () =>
                    context.read<TrashBloc>().add(TrashEvent.delete(object)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrashPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
} 