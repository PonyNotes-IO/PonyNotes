import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/_folder_header.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SectionFolder extends StatefulWidget {
  const SectionFolder({
    super.key,
    required this.title,
    required this.spaceType,
    required this.views,
    this.isHoverEnabled = true,
    required this.expandButtonTooltip,
    required this.addButtonTooltip,
  });

  final String title;
  final FolderSpaceType spaceType;
  final List<ViewPB> views;
  final bool isHoverEnabled;
  final String expandButtonTooltip;
  final String addButtonTooltip;

  @override
  State<SectionFolder> createState() => _SectionFolderState();
}

class _SectionFolderState extends State<SectionFolder> {
  final isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: BlocProvider<FolderBloc>(
        create: (_) => FolderBloc(type: widget.spaceType)
          ..add(const FolderEvent.initial()),
        child: BlocBuilder<FolderBloc, FolderState>(
          builder: (context, state) => Column(
            children: [
              _buildHeader(context),
              // Pages
              const VSpace(4.0),
              ..._buildViews(context, state, isHovered),
              // Add a placeholder if there are no views
              _buildDraggablePlaceholder(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // 获取当前工作空间ID作为parentViewId
    final parentViewId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId;
    
    return FolderHeader(
      title: widget.title,
      isExpanded: context.watch<FolderBloc>().state.isExpanded,
      expandButtonTooltip: widget.expandButtonTooltip,
      addButtonTooltip: widget.addButtonTooltip,
      onPressed: () =>
          context.read<FolderBloc>().add(const FolderEvent.expandOrUnExpand()),
      onAdded: () {
        context.read<SidebarSectionsBloc>().add(
              SidebarSectionsEvent.createRootViewInSection(
                name: '',
                index: 0,
                viewSection: widget.spaceType.toViewSectionPB,
              ),
            );

        context
            .read<FolderBloc>()
            .add(const FolderEvent.expandOrUnExpand(isExpanded: true));
      },
      // 只为"我的空间"提供选择菜单功能
      parentViewId: widget.title == "我的空间" ? parentViewId : null,
      onViewSelected: widget.title == "我的空间" ? _onViewSelected : null,
    );
  }

  void _onViewSelected(
    PluginBuilder pluginBuilder,
    String? name,
    List<int>? initialDataBytes,
    bool openAfterCreated,
    bool createNewView,
  ) async {
    // 获取当前工作空间ID作为parentViewId
    final parentViewId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId;
    
    if (parentViewId == null) return;

    // 根据插件类型确定视图名称
    final viewName = ![ViewLayoutPB.Document, ViewLayoutPB.Chat]
            .contains(pluginBuilder.layoutType)
        ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
        : '';

    try {
      // 使用ViewBackendService创建指定类型的视图
      final result = await ViewBackendService.createView(
        layoutType: pluginBuilder.layoutType!,
        parentViewId: parentViewId,
        name: viewName,
        openAfterCreate: openAfterCreated,
        initialDataBytes: initialDataBytes,
        index: 0,
        section: widget.spaceType.toViewSectionPB,
      );

      result.fold(
        (view) {
          // 创建成功，展开文件夹以显示新创建的视图
          context
              .read<FolderBloc>()
              .add(const FolderEvent.expandOrUnExpand(isExpanded: true));
          
          // 不需要手动刷新，系统会自动更新侧边栏
        },
        (error) {
          // 处理错误，可以显示错误消息
          // TODO: 可以添加错误提示
        },
      );
    } catch (e) {
      // 处理异常
      // TODO: 可以添加异常处理
    }
  }

  Iterable<Widget> _buildViews(
    BuildContext context,
    FolderState state,
    ValueNotifier<bool> isHovered,
  ) {
    if (!state.isExpanded) {
      return [];
    }

    // 为"我的空间"的子项目设置适当的缩进级别
    final bool isMySpaceSection = widget.title == "我的空间";
    final int itemLevel = isMySpaceSection ? 1 : 0; // 我的空间下的项目缩进一级

    return widget.views.map(
      (view) => ViewItem(
        key: ValueKey('${widget.spaceType.name} ${view.id}'),
        spaceType: widget.spaceType,
        engagedInExpanding: true,
        isFirstChild: view.id == widget.views.first.id,
        view: view,
        level: itemLevel, // 使用计算得出的缩进级别
        leftPadding: HomeSpaceViewSizes.leftPadding,
        isFeedback: false,
        isHovered: isHovered,
        enableRightClickContext: true,
        onSelected: (viewContext, view) {
          if (HardwareKeyboard.instance.isControlPressed) {
            context.read<TabsBloc>().openTab(view);
          }

          context.read<TabsBloc>().openPlugin(view);
        },
        onTertiarySelected: (viewContext, view) =>
            context.read<TabsBloc>().openTab(view),
        isHoverEnabled: widget.isHoverEnabled,
      ),
    );
  }

  Widget _buildDraggablePlaceholder(BuildContext context) {
    if (widget.views.isNotEmpty) {
      return const SizedBox.shrink();
    }
    final parentViewId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId;
    return ViewItem(
      spaceType: widget.spaceType,
      view: ViewPB(parentViewId: parentViewId ?? ''),
      level: 0,
      leftPadding: HomeSpaceViewSizes.leftPadding,
      isFeedback: false,
      onSelected: (_, __) {},
      isHoverEnabled: widget.isHoverEnabled,
      isPlaceholder: true,
    );
  }
}
