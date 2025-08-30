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
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_service.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'dart:ui' as ui;


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
  TrashPB? _selectedObject;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Row(
        children: [
          // 左侧回收站侧边栏
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                // 顶部工具栏
                Container(
                  height: 50,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 24), // 调整为24px左边距，与列表项保持一致
                      Expanded(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 0), // 确保没有额外的左边距
                              child: FlowyText.medium(
                                '回收站',
                                fontSize: FontSizes.s18, // 增大字体
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            // 当有内容时显示提示文字
                            BlocBuilder<TrashBloc, TrashState>(
                              builder: (context, state) {
                                if (state.objects.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 24), // 调整为24px右边距
                                    child: FlowyText.regular(
                                      '回收站的笔记将在7天后永久删除',
                                      fontSize: FontSizes.s12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 侧边栏内容
                Expanded(
                  child: _buildExpandedSidebar(),
                ),
              ],
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
      ),
    );
  }

  Widget _buildExpandedSidebar() {
    return TrashSidebarContent(
      selectedObject: _selectedObject,
      onObjectSelected: (object) {
        setState(() {
          _selectedObject = object;
        });
      },
    );
  }



  Widget _buildMainContent() {
    return BlocBuilder<TrashBloc, TrashState>(
      builder: (context, state) {
        // 如果回收站为空，显示空白
        if (state.objects.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // 如果没有选中项，显示空白
        if (_selectedObject == null) {
          return const SizedBox.shrink();
        }
        
        // 如果选中了项目，显示其内容
        return _buildSelectedObjectContent(context, _selectedObject!);
      },
    );
  }
  
  Widget _buildSelectedObjectContent(BuildContext context, TrashPB object) {
    // 创建一个临时的 ViewPB 来显示文档内容
    final tempView = ViewPB.create()
      ..id = object.id
      ..name = object.name.isEmpty 
          ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
          : object.name
      ..layout = ViewLayoutPB.Document
      ..createTime = object.createTime
      ..lastEdited = object.modifiedTime;

    return TrashDocumentView(view: tempView);
  }
  
  String _formatDate($fixnum.Int64 timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    return DateFormat('yyyy/MM/dd').format(date);
  }
}

// 回收站侧边栏内容组件
class TrashSidebarContent extends StatefulWidget {
  const TrashSidebarContent({
    super.key,
    this.selectedObject,
    this.onObjectSelected,
  });

  final TrashPB? selectedObject;
  final Function(TrashPB)? onObjectSelected;

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
    return BlocBuilder<TrashBloc, TrashState>(
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0), // 统一左右边距为16px
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // 统一左右边距为16px
        itemCount: state.objects.length,
        itemBuilder: (context, index) {
          final object = state.objects[index];
          final isSelected = widget.selectedObject?.id == object.id;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : null,
            ),
            child: InkWell(
              onTap: () {
                widget.onObjectSelected?.call(object);
              },
              borderRadius: BorderRadius.circular(8),
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

// 回收站文档视图组件
class TrashDocumentView extends StatelessWidget {
  const TrashDocumentView({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DocumentBloc(documentId: view.id)
            ..add(const DocumentEvent.initial()),
        ),
        BlocProvider(
          create: (context) => ViewBloc(view: view)..add(const ViewEvent.initial()),
        ),
      ],
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          final editorState = state.editorState;
          final error = state.error;
          if (error != null || editorState == null) {
            return _buildErrorView(context, error);
          }

          return _buildDocumentView(context, editorState);
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, FlowyError? error) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '无法加载文档内容',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此文档可能已被永久删除',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '错误信息: ${error.msg}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentView(BuildContext context, EditorState editorState) {
    // 设置编辑器为只读状态
    editorState.editable = false;
    
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Expanded(
          child: _buildReadOnlyEditor(context, editorState),
        ),
      ],
    );
  }

  Widget _buildReadOnlyEditor(BuildContext context, EditorState editorState) {
    final isRTL = context.read<AppearanceSettingsCubit>().state.layoutDirection ==
        LayoutDirection.rtlLayout;
    final textDirection = isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: _buildReadOnlyContent(context, editorState),
        ),
      ),
    );
  }

  Widget _buildReadOnlyContent(BuildContext context, EditorState editorState) {
    // 获取文档内容并转换为只读显示
    final document = editorState.document;
    final nodes = document.root.children;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes.map((node) {
        return _buildReadOnlyNode(context, node);
      }).toList(),
    );
  }

  Widget _buildReadOnlyNode(BuildContext context, Node node) {
    if (node.type == 'paragraph') {
      return _buildReadOnlyParagraph(context, node);
    } else if (node.type == 'heading') {
      return _buildReadOnlyHeading(context, node);
    } else if (node.type == 'bulleted_list') {
      return _buildReadOnlyBulletedList(context, node);
    } else if (node.type == 'numbered_list') {
      return _buildReadOnlyNumberedList(context, node);
    } else if (node.type == 'quote') {
      return _buildReadOnlyQuote(context, node);
    } else if (node.type == 'code') {
      return _buildReadOnlyCode(context, node);
    } else if (node.type == 'divider') {
      return _buildReadOnlyDivider(context);
    } else if (node.type == 'image') {
      return _buildReadOnlyImage(context, node);
    } else {
      // 默认段落处理
      return _buildReadOnlyParagraph(context, node);
    }
  }

  Widget _buildReadOnlyParagraph(BuildContext context, Node node) {
    final text = _extractTextFromNode(node);
    if (text.isEmpty) {
      return const SizedBox(height: 16);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildReadOnlyHeading(BuildContext context, Node node) {
    final text = _extractTextFromNode(node);
    final level = node.attributes['level'] ?? 1;
    
    TextStyle? headingStyle;
    switch (level) {
      case 1:
        headingStyle = Theme.of(context).textTheme.headlineLarge;
        break;
      case 2:
        headingStyle = Theme.of(context).textTheme.headlineMedium;
        break;
      case 3:
        headingStyle = Theme.of(context).textTheme.headlineSmall;
        break;
      default:
        headingStyle = Theme.of(context).textTheme.titleLarge;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        text,
        style: headingStyle?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReadOnlyBulletedList(BuildContext context, Node node) {
    final text = _extractTextFromNode(node);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNumberedList(BuildContext context, Node node) {
    final text = _extractTextFromNode(node);
    final index = node.attributes['number'] ?? 1;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyQuote(BuildContext context, Node node) {
    final text = _extractTextFromNode(node);
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildReadOnlyCode(BuildContext context, Node node) {
    final text = _extractTextFromNode(node);
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildReadOnlyDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      height: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildReadOnlyImage(BuildContext context, Node node) {
    final url = node.attributes['url'] ?? '';
    if (url.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _extractTextFromNode(Node node) {
    // 使用 delta 来获取文本内容
    final text = node.delta?.toPlainText() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
    
    // 如果有子节点，递归处理
    if (node.children.isNotEmpty) {
      return node.children.map((child) => _extractTextFromNode(child)).join('');
    }
    
    return '';
  }

  Future<List<ViewPB>> _getViewAncestors(String viewId) async {
    try {
      // 使用 ViewBackendService 获取视图祖先
      final result = await ViewBackendService.getViewAncestors(viewId);
      return result.fold(
        (ancestors) => ancestors.items,
        (error) => <ViewPB>[],
      );
    } catch (e) {
      return <ViewPB>[];
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 面包屑导航 - 显示原始路径
          FutureBuilder<List<ViewPB>>(
            future: _getViewAncestors(view.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      const FlowySvg(FlowySvgs.icon_folder_s, size: Size.square(14)),
                      const HSpace(4.0),
                      FlowyText.regular(
                        '加载中...',
                        fontSize: 14.0,
                        figmaLineHeight: 18.0,
                      ),
                    ],
                  ),
                );
              }
              
              final ancestors = snapshot.data ?? [];
              if (ancestors.isEmpty) {
                // 如果没有祖先路径，显示回收站
                return SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      const FlowySvg(FlowySvgs.trash_s, size: Size.square(14)),
                      const HSpace(4.0),
                      FlowyText.regular(
                        LocaleKeys.trash_text.tr(),
                        fontSize: 14.0,
                        figmaLineHeight: 18.0,
                      ),
                    ],
                  ),
                );
              }
              
              // 显示原始路径 - 跳过第一个（workspace），从第二个开始显示
              return SizedBox(
                height: 32,
                child: Row(
                  children: [
                    for (int i = 1; i < ancestors.length; i++) ...[
                      if (i > 1) ...[
                        const FlowySvg(FlowySvgs.title_bar_divider_s),
                        const HSpace(4.0),
                      ],
                      Container(
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Row(
                          children: [
                            if (ancestors[i].icon.value.isNotEmpty) ...[
                              RawEmojiIconWidget(
                                emoji: ancestors[i].icon.toEmojiIconData(),
                                emojiSize: 14.0,
                              ),
                              const HSpace(4.0),
                            ],
                            FlowyText.regular(
                              ancestors[i].name.isEmpty 
                                  ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
                                  : ancestors[i].name,
                              fontSize: 14.0,
                              overflow: TextOverflow.ellipsis,
                              figmaLineHeight: 18.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // 标题
          Text(
            view.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
} 