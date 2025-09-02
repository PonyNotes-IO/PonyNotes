import 'package:appflowy/generated/flowy_svgs.g.dart';

import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_item_dropdown.dart';

/// 我的空间菜单项类型
enum MySpaceItemType {
  folder,      // 文件夹
  notebook,    // 笔记本
  note,        // 笔记
}

/// 我的空间菜单项数据模型
class MySpaceMenuItem {
  final String id;
  final String name;
  final String? icon;
  final MySpaceItemType type;
  final List<MySpaceMenuItem> children;
  final bool isExpanded;
  final ViewPB? view; // 添加关联的视图对象，用于类型识别

  const MySpaceMenuItem({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    this.children = const [],
    this.isExpanded = false,
    this.view, // 添加视图参数
  });

  MySpaceMenuItem copyWith({
    String? id,
    String? name,
    String? icon,
    MySpaceItemType? type,
    List<MySpaceMenuItem>? children,
    bool? isExpanded,
    ViewPB? view,
  }) {
    return MySpaceMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      view: view ?? this.view,
    );
  }
}

// 重命名功能已改为内联编辑模式，不再使用弹窗

/// 我的空间菜单组件
class SidebarMySpaceMenu extends StatefulWidget {
  const SidebarMySpaceMenu({super.key});

  @override
  State<SidebarMySpaceMenu> createState() => _SidebarMySpaceMenuState();
}

class _SidebarMySpaceMenuState extends State<SidebarMySpaceMenu> {
  // 最大文件夹深度限制
  static const int _maxFolderDepth = 6;
  
  // 是否全部展开的状态（暂未使用）
  // bool _isAllExpanded = false;
  // 我的空间主菜单是否展开的状态
  bool _isMainMenuExpanded = true;
  
  // 我的空间菜单项列表 - 从SidebarSectionsBloc同步获取
  List<MySpaceMenuItem> _menuItems = <MySpaceMenuItem>[];
  
  // 保存上次的privateViews，用于检测数据变化，避免重复同步
  List<ViewPB> _lastPrivateViews = [];
  
  // 重命名缓存：记录最近重命名的项目，防止被同步覆盖
  final Map<String, String> _recentRenameCache = {};
  final Map<String, DateTime> _renameCacheTimestamp = {};
  
  // 最近创建的视图缓存：记录最近创建的视图ID和时间戳，防止在数据同步时被覆盖
  final Map<String, DateTime> _recentlyCreatedViews = {};
  
  // 内联编辑状态：记录正在编辑的项目ID
  String? _editingItemId;
  final TextEditingController _editingController = TextEditingController();
  final FocusNode _editingFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 在下一帧同步菜单项，确保context已准备好
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _syncMenuItemsFromBloc();
      }
    });
  }

  @override
  void dispose() {
    _editingController.dispose();
    _editingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SidebarSectionsBloc, SidebarSectionsState>(
      listener: (context, state) {
        // 只有当privateViews真正发生变化时才同步
        final newPrivateViews = state.section.privateViews;
        if (!_isPrivateViewsEqual(newPrivateViews, _lastPrivateViews)) {
          _lastPrivateViews = List.from(newPrivateViews);
          _syncMenuItemsFromBloc();
        }
      },
      child: Column(
        children: [
          // 我的空间标题
          _buildHeader(),
          // 菜单项列表（根据主菜单展开状态显示/隐藏）
          if (_isMainMenuExpanded) ...[
            const VSpace(8.0),
            ..._buildMenuItems(_menuItems, 0),
          ],
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // 文件夹图标
          FlowySvg(
            FlowySvgs.icon_folder_s,
            size: const Size.square(16.0),
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const HSpace(8.0),
          // 可点击的标题
          GestureDetector(
            onTap: () {
              setState(() {
                _isMainMenuExpanded = !_isMainMenuExpanded;
              });
            },
            child: Text(
              '我的空间',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          // 清理重复项按钮
          // if (kDebugMode) // 只在调试模式下显示
          //   GestureDetector(
          //     onTap: _cleanupDuplicateViews,
          //     child: Container(
          //       padding: const EdgeInsets.all(4.0),
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(4.0),
          //         color: Colors.orange.withOpacity(0.1),
          //       ),
          //       child: Icon(
          //         Icons.cleaning_services,
          //         size: 16,
          //         color: Colors.orange,
          //       ),
          //     ),
          //   ),
          if (kDebugMode) const HSpace(8.0),
          // 添加子项目下拉按钮
          AddItemButton(
            onItemSelected: (type) {
              _addRootItemWithDefaultName(_convertToMySpaceItemType(type));
            },
            allowedTypes: const [AddItemType.folder, AddItemType.notebook, AddItemType.note],
            showOnHover: true,
            buttonSize: 16.0,
          ),
          const HSpace(8.0),
          // 主菜单展开/收起按钮
          GestureDetector(
            onTap: () {
              setState(() {
                _isMainMenuExpanded = !_isMainMenuExpanded;
              });
            },
            child: Icon(
              _isMainMenuExpanded 
                  ? Icons.keyboard_arrow_down 
                  : Icons.keyboard_arrow_right,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),

        ],
      ),
    );
  }

  /// 构建菜单项列表
  List<Widget> _buildMenuItems(List<MySpaceMenuItem> items, int level) {
    return items.map((item) => _buildMenuItem(item, level)).toList();
  }

  /// 构建单个菜单项
  Widget _buildMenuItem(MySpaceMenuItem item, int level) {
    final hasChildren = item.children.isNotEmpty;
    // final canHaveChildren = item.type == MySpaceItemType.folder || 
    //                        item.type == MySpaceItemType.notebook;
    
    return Column(
      children: [
        // 菜单项本身
        _buildMenuItemRow(item, level, hasChildren),
        // 子项目（如果展开且有子项目）
        if (item.isExpanded && hasChildren) ...[
          const VSpace(2.0),
          ..._buildMenuItems(item.children, level + 1),
        ],
      ],
    );
  }

  /// 构建菜单项行
  Widget _buildMenuItemRow(MySpaceMenuItem item, int level, bool hasChildren) {
    // final theme = AppFlowyTheme.of(context);
    final isFolder = item.type == MySpaceItemType.folder;
    final isNotebook = item.type == MySpaceItemType.notebook;
    final isNote = item.type == MySpaceItemType.note;
    
    // 根据层级和类型确定样式
    final leftPadding = 8.0 + (level * 20.0);
    final itemColor = isNote 
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
        : Theme.of(context).colorScheme.onSurface;
    
    return Container(
      margin: EdgeInsets.only(left: leftPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onMenuItemTap(item),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _getBorderColor(level, item.type),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                // 展开/收起箭头（如果有子项目且可以展开）
                if (hasChildren && (isFolder || isNotebook)) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _toggleExpanded(item);
                      });
                    },
                    child: Icon(
                      item.isExpanded 
                          ? Icons.keyboard_arrow_down 
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: itemColor.withOpacity(0.6),
                    ),
                  ),
                  const HSpace(4),
                ] else ...[
                  const HSpace(20), // 占位，保持对齐
                ],
                // 图标
                if (item.icon != null) ...[
                  Text(
                    item.icon!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const HSpace(8),
                ] else ...[
                  Icon(
                    isFolder ? Icons.folder : 
                    isNotebook ? Icons.book : Icons.note,
                    size: 16,
                    color: itemColor.withOpacity(0.7),
                  ),
                  const HSpace(8),
                ],
                // 名称或编辑框
                Expanded(
                  child: _editingItemId == item.id
                      ? _buildInlineEditField(item)
                      : GestureDetector(
                          onSecondaryTap: () => _showContextMenu(context, item),
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: itemColor,
                              fontSize: isNote ? 13 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
                // 三点菜单按钮
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 16),
                  onPressed: () => _showMoreActionsMenu(context, item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: itemColor.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取边框颜色
  Color _getBorderColor(int level, MySpaceItemType type) {
    if (level == 0) {
      return Theme.of(context).colorScheme.outline.withOpacity(0.5);
    } else {
      return Theme.of(context).colorScheme.outline.withOpacity(0.3);
    }
  }

  /// 显示更多操作菜单
  void _showMoreActionsMenu(BuildContext context, MySpaceMenuItem item) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + button.size.width,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items: _buildMoreActionsMenuItems(item),
    ).then((value) {
      if (value != null) {
        _handleMoreActionsMenuAction(value, item);
      }
    });
  }

  /// 显示右键菜单
  void _showContextMenu(BuildContext context, MySpaceMenuItem item) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + button.size.width,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items: _buildContextMenuItems(item),
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value, item);
      }
    });
  }

  /// 构建更多操作菜单项
  List<PopupMenuEntry<String>> _buildMoreActionsMenuItems(MySpaceMenuItem item) {
    final List<PopupMenuEntry<String>> menuItems = [];
    
    // 如果是文件夹或笔记本，添加子项目选项
    // 根据父项目类型确定允许创建的子项目类型
    MySpaceItemType parentType = item.type;
    
    // 如果有关联的视图，通过视图识别真实类型
    if (item.view != null) {
      parentType = _identifyViewType(item.view!);
    }
    
    final allowedChildTypes = _getAllowedChildTypes(parentType, parentItem: item);
    
    // 只有当允许创建子项目时才显示创建菜单
    if (allowedChildTypes.isNotEmpty) {
      // 根据允许的类型添加相应的菜单项
      if (allowedChildTypes.contains(MySpaceItemType.folder)) {
        menuItems.add(
          PopupMenuItem<String>(
            value: 'add_folder',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder, size: 16),
                const HSpace(8),
                const Text('添加文件夹'),
              ],
            ),
          ),
        );
      }
      
      if (allowedChildTypes.contains(MySpaceItemType.notebook)) {
        menuItems.add(
          PopupMenuItem<String>(
            value: 'add_notebook',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book, size: 16),
                const HSpace(8),
                const Text('添加笔记本'),
              ],
            ),
          ),
        );
      }
      
      if (allowedChildTypes.contains(MySpaceItemType.note)) {
        menuItems.add(
          PopupMenuItem<String>(
            value: 'add_note',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.note, size: 16),
                const HSpace(8),
                const Text('添加笔记'),
              ],
            ),
          ),
        );
      }
      
      // 分隔线
      menuItems.add(const PopupMenuDivider());
    }
    
    // 重命名
    menuItems.add(
      PopupMenuItem<String>(
        value: 'rename',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 16),
            const HSpace(8),
            const Text('重命名'),
          ],
        ),
      ),
    );
    
    // 删除
    menuItems.add(
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const HSpace(8),
            Text(
              '删除',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
    
    return menuItems;
  }

  /// 处理更多操作菜单操作
  void _handleMoreActionsMenuAction(String action, MySpaceMenuItem item) {
    switch (action) {
      case 'add_folder':
        _addChildItemWithDefaultName(item, MySpaceItemType.folder);
        break;
      case 'add_notebook':
        _addChildItemWithDefaultName(item, MySpaceItemType.notebook);
        break;
      case 'add_note':
        _addChildItemWithDefaultName(item, MySpaceItemType.note);
        break;
      case 'rename':
        _onRenameItem(item);
        break;
      case 'delete':
        _onDeleteItem(item);
        break;
    }
  }

  /// 构建右键菜单项
  List<PopupMenuEntry<String>> _buildContextMenuItems(MySpaceMenuItem item) {
    final List<PopupMenuEntry<String>> items = [];
    
    // 重命名
    items.add(
      PopupMenuItem<String>(
        value: 'rename',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 16),
            const HSpace(8),
            const Text('重命名'),
          ],
        ),
      ),
    );
    
    // 移动到（仅文件夹和笔记本）
    if (item.type == MySpaceItemType.folder || item.type == MySpaceItemType.notebook) {
      items.add(
        PopupMenuItem<String>(
          value: 'move',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.drive_file_move_outline, size: 16),
              const HSpace(8),
              const Text('移动到'),
              const HSpace(16),
              Text(
                '⌘⌥M',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 分享
    items.add(
      PopupMenuItem<String>(
        value: 'share',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share_outlined, size: 16),
            const HSpace(8),
            const Text('分享'),
            const HSpace(16),
            Text(
              '⌘⌥S',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
    
    // 加星
    items.add(
      PopupMenuItem<String>(
        value: 'favorite',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_outline, size: 16),
            const HSpace(8),
            const Text('加星'),
            const HSpace(16),
            Text(
              '⌘⇧C',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
    
    // 复制
    items.add(
      PopupMenuItem<String>(
        value: 'copy',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_outlined, size: 16),
            const HSpace(8),
            const Text('复制'),
            const HSpace(16),
            Text(
              '⌘C',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
    
    // 分隔线
    items.add(const PopupMenuDivider());
    
    // 删除
    items.add(
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const HSpace(8),
            Text(
              '删除',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
    
    return items;
  }

  /// 处理右键菜单操作
  void _handleContextMenuAction(String action, MySpaceMenuItem item) {
    switch (action) {
      case 'rename':
        _onRenameItem(item);
        break;
      case 'move':
        _onMoveItem(item);
        break;
      case 'share':
        _onShareItem(item);
        break;
      case 'favorite':
        _onFavoriteItem(item);
        break;
      case 'copy':
        _onCopyItem(item);
        break;
      case 'delete':
        _onDeleteItem(item);
        break;
    }
  }

  /// 移动项目
  void _onMoveItem(MySpaceMenuItem item) {
    // TODO: 实现移动功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('移动 "${item.name}" 功能待实现')),
    );
  }

  /// 分享项目
  void _onShareItem(MySpaceMenuItem item) {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享 "${item.name}" 功能待实现')),
    );
  }

  /// 加星项目
  void _onFavoriteItem(MySpaceMenuItem item) {
    // TODO: 实现加星功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('加星 "${item.name}" 功能待实现')),
    );
  }

  /// 复制项目
  void _onCopyItem(MySpaceMenuItem item) {
    // TODO: 实现复制功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('复制 "${item.name}" 功能待实现')),
    );
  }



  /// 菜单项点击处理
  void _onMenuItemTap(MySpaceMenuItem item) {
    if (item.children.isNotEmpty && 
        (item.type == MySpaceItemType.folder || item.type == MySpaceItemType.notebook)) {
      // 切换展开状态
      setState(() {
        _toggleExpanded(item);
      });
    } else if (item.type == MySpaceItemType.note) {
      // 处理笔记点击 - 复用"个人的"主菜单的打开逻辑
      _openExistingDocument(item);
    } else {
      debugPrint('点击了项目: ${item.name}');
    }
  }

  /// 切换展开状态
  void _toggleExpanded(MySpaceMenuItem item) {
    _toggleExpandedRecursive(_menuItems, item.id);
  }

  /// 递归切换展开状态
  bool _toggleExpandedRecursive(List<MySpaceMenuItem> items, String targetId) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == targetId) {
        items[i] = items[i].copyWith(isExpanded: !items[i].isExpanded);
        return true;
      }
      if (_toggleExpandedRecursive(items[i].children, targetId)) {
        return true;
      }
    }
    return false;
  }

  // 已移除弹窗式添加项目方法，改为使用下拉菜单



  /// 获取类型名称
  String _getTypeName(MySpaceItemType type) {
    switch (type) {
      case MySpaceItemType.folder:
        return '文件夹';
      case MySpaceItemType.notebook:
        return '笔记本';
      case MySpaceItemType.note:
        return '笔记';
    }
  }

  // 已移除 _getTypeIcon 方法，改为使用emoji显示

  /// 获取类型emoji
  String _getTypeEmoji(MySpaceItemType type) {
    switch (type) {
      case MySpaceItemType.folder:
        return '📁';
      case MySpaceItemType.notebook:
        return '📚';
      case MySpaceItemType.note:
        return '📝';
    }
  }

  // 展开/收起所有项目方法暂未使用
  // void _expandAll() {
  //   _isAllExpanded = true;
  //   _expandAllRecursive(_menuItems);
  // }
  //
  // void _collapseAll() {
  //   _isAllExpanded = false;
  //   _collapseAllRecursive(_menuItems);
  // }

  // 递归展开/收起所有项目方法暂未使用
  // void _expandAllRecursive(List<MySpaceMenuItem> items) {
  //   for (int i = 0; i < items.length; i++) {
  //     if (items[i].children.isNotEmpty) {
  //       items[i] = items[i].copyWith(isExpanded: true);
  //       _expandAllRecursive(items[i].children);
  //     }
  // }
  //
  // void _collapseAllRecursive(List<MySpaceMenuItem> items) {
  //   for (int i = 0; i < items.length; i++) {
  //     if (items[i].children.isNotEmpty) {
  //       items[i] = items[i].copyWith(isExpanded: false);
  //       _collapseAllRecursive(items[i].children);
  //     }
  //   }
  // }

  /// 重命名项目
  void _onRenameItem(MySpaceMenuItem item) {
    setState(() {
      _editingItemId = item.id;
      _editingController.text = item.name;
    });
    
    // 延迟聚焦到编辑框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editingFocusNode.requestFocus();
      _editingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editingController.text.length,
      );
    });
  }

  /// 构建内联编辑框
  Widget _buildInlineEditField(MySpaceMenuItem item) {
    return TextField(
      controller: _editingController,
      focusNode: _editingFocusNode,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: item.type == MySpaceItemType.note ? 13 : 14,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        isDense: true,
      ),
      onSubmitted: (newName) => _confirmRename(item, newName),
      onTapOutside: (_) => _cancelRename(),
    );
  }

  /// 确认重命名
  void _confirmRename(MySpaceMenuItem item, String newName) {
    final trimmedName = newName.trim();
    
    // 检查名称是否为空
    if (trimmedName.isEmpty) {
      _showRenameError('项目名称不能为空');
      return;
    }
    
    // 检查名称是否有变化
    if (trimmedName == item.name) {
      _cancelRename();
      return;
    }
    
    // 检查同目录下同类项目名称是否重复
    if (_isDuplicateName(item, trimmedName)) {
      _showRenameError('同目录下已存在同名的${_getTypeName(item.type)}');
      return;
    }
    
    // 执行重命名
    _executeRename(item, trimmedName);
  }

  /// 取消重命名
  void _cancelRename() {
    setState(() {
      _editingItemId = null;
      _editingController.clear();
    });
  }

  /// 显示重命名错误
  void _showRenameError(String message) {
    showMessageToast(message, context: context);
    // 重新聚焦到编辑框
    _editingFocusNode.requestFocus();
  }

  /// 检查同目录下同类项目名称是否重复
  bool _isDuplicateName(MySpaceMenuItem item, String newName) {
    // 获取父项目的子项目列表
    List<MySpaceMenuItem> siblings;
    
    if (item.view?.parentViewId != null && item.view!.parentViewId.isNotEmpty) {
      // 子项目：查找父项目的子项目列表
      final parentItem = _findItemById(_menuItems, item.view!.parentViewId);
      siblings = parentItem?.children ?? [];
    } else {
      // 根级项目：使用根级菜单项列表
      siblings = _menuItems;
    }
    
    // 检查同类型的兄弟项目中是否有同名的
    return siblings.any((sibling) =>
        sibling.id != item.id && // 排除自身
        sibling.type == item.type && // 同类型
        sibling.name == newName // 同名称
    );
  }

  /// 执行重命名操作
  void _executeRename(MySpaceMenuItem item, String newName) async {
    // 取消编辑状态
    setState(() {
      _editingItemId = null;
      _editingController.clear();
    });
    
    // 先更新UI（提供即时反馈）
    final oldName = item.name;
    final oldParentId = item.view?.parentViewId;
    
    // 立即更新本地状态，包括所有层级中的项目
    setState(() {
      _renameItemRecursive(_menuItems, item.id, newName);
    });

    try {
      // 调用后端API进行真实重命名
      if (item.view != null) {
        final result = await ViewBackendService.updateView(
          viewId: item.id,
          name: newName,
        );
        
        result.fold(
          (success) async {
            // 重命名成功，显示提示
            showMessageToast('已重命名为: $newName', context: context);
            
            // 添加到重命名缓存，防止后续同步覆盖
            _addToRenameCache(item.id, newName);
            
            // 通知工作区标题栏更新（如果当前视图正在显示）
            _notifyWorkspaceViewUpdate(item.id, newName);
            
            // 延迟同步，给后端时间更新数据
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              await _syncMenuItemsFromBloc();
              
              // 如果重命名的是子项目，确保父项目保持展开状态
              if (oldParentId != null && oldParentId.isNotEmpty) {
                _ensureParentExpanded(oldParentId);
              }
            }
          },
          (error) {
            // 重命名失败，显示错误并恢复UI状态
            showMessageToast('重命名失败: ${error.msg}', context: context);
            
            // 恢复UI状态：恢复原名称
            setState(() {
              _renameItemRecursive(_menuItems, item.id, oldName);
            });
          },
        );
      } else {
        // 如果没有关联的ViewPB，说明是仅UI层的项目
        showMessageToast('已重命名为: $newName', context: context);
      }
    } catch (e) {
      // 处理异常情况
      showMessageToast('重命名操作失败: $e', context: context);
      
      // 恢复UI状态
      setState(() {
        _renameItemRecursive(_menuItems, item.id, oldName);
      });
    }
  }

  /// 通知工作区视图更新（确保标题栏同步更新）
  void _notifyWorkspaceViewUpdate(String viewId, String newName) {
    try {
      // 通知工作区标题更新
      debugPrint('通知工作区视图更新: $viewId -> $newName');
      
      // 可以在这里添加更多的刷新逻辑来确保工作区标题更新
      // 比如触发相关组件的重新渲染
    } catch (e) {
      debugPrint('通知工作区视图更新失败: $e');
    }
  }

  /// 添加项目到重命名缓存
  void _addToRenameCache(String viewId, String newName) {
    _recentRenameCache[viewId] = newName;
    _renameCacheTimestamp[viewId] = DateTime.now();
    debugPrint('添加到重命名缓存: $viewId -> $newName');
  }

  /// 从重命名缓存中获取名称（如果存在且未过期）
  String? _getFromRenameCache(String viewId) {
    final cachedName = _recentRenameCache[viewId];
    final timestamp = _renameCacheTimestamp[viewId];
    
    if (cachedName != null && timestamp != null) {
      // 缓存有效期为5秒
      final isExpired = DateTime.now().difference(timestamp).inSeconds > 5;
      if (isExpired) {
        _recentRenameCache.remove(viewId);
        _renameCacheTimestamp.remove(viewId);
        debugPrint('重命名缓存已过期: $viewId');
        return null;
      }
      debugPrint('从重命名缓存获取名称: $viewId -> $cachedName');
      return cachedName;
    }
    return null;
  }

  /// 清理过期的重命名缓存
  void _cleanExpiredRenameCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _renameCacheTimestamp.entries) {
      if (now.difference(entry.value).inSeconds > 5) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _recentRenameCache.remove(key);
      _renameCacheTimestamp.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('清理过期重命名缓存: ${expiredKeys.length} 项');
    }
  }
  
  /// 清理过期的最近创建视图缓存（超过60秒）
  void _cleanExpiredRecentlyCreatedCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _recentlyCreatedViews.entries) {
      if (now.difference(entry.value).inSeconds > 60) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _recentlyCreatedViews.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('清理过期的最近创建视图缓存: ${expiredKeys.length} 项');
    }
  }

  /// 递归重命名项目
  bool _renameItemRecursive(List<MySpaceMenuItem> items, String targetId, String newName) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == targetId) {
        items[i] = items[i].copyWith(name: newName);
        return true;
      }
      if (_renameItemRecursive(items[i].children, targetId, newName)) {
        return true;
      }
    }
    return false;
  }

  /// 删除项目
  void _onDeleteItem(MySpaceMenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除"${item.name}"吗？\n\n删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 执行删除操作
  void _deleteItem(MySpaceMenuItem item) async {
    try {
      // 1. 先从UI层移除（提供即时反馈）
      setState(() {
        _deleteItemRecursive(_menuItems, item.id);
      });

      // 2. 调用后端API真实删除 - 现在所有类型都需要删除后端实体
      if (item.view != null) {
        // 如果有关联的ViewPB，说明是真实的后端实体，需要调用删除API
        final result = await ViewBackendService.deleteView(viewId: item.id);
        
        result.fold(
          (success) {
            // 删除成功，显示提示
            showMessageToast('已删除${_getTypeName(item.type)}: ${item.name}', context: context);
            // 同步菜单项以确保UI与后端一致
            _syncMenuItemsFromBloc();
            
            // 安排多次延迟同步，确保删除在所有组件中生效
            _scheduleMultipleSyncs();
          },
          (error) {
            // 删除失败，显示错误并恢复UI状态
            showMessageToast('删除失败: ${error.msg}', context: context);
            
            // 恢复UI状态：重新添加项目
            setState(() {
              _menuItems.add(item);
            });
          },
        );
      } else {
        // 如果没有关联的ViewPB，说明是仅UI层的项目（不太可能出现在当前实现中）
        showMessageToast('已删除${_getTypeName(item.type)}: ${item.name}', context: context);
      }
    } catch (e) {
      // 处理异常情况
      showMessageToast('删除操作失败: $e', context: context);
      
      // 恢复UI状态
      setState(() {
        _menuItems.add(item);
      });
    }
  }

  /// 递归删除项目
  bool _deleteItemRecursive(List<MySpaceMenuItem> items, String targetId) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == targetId) {
        items.removeAt(i);
        return true;
      }
      if (_deleteItemRecursive(items[i].children, targetId)) {
        return true;
      }
    }
    return false;
  }

  // 已移除弹窗式添加根项目方法，改为使用下拉菜单

  /// 添加根级项目
  void _addRootItem(MySpaceItemType type, String name) async {
    // 为所有类型创建真实的后端实体
    await _createRealBackendEntity(type, name, null);
  }

  /// 添加根级项目（使用默认名称）
  void _addRootItemWithDefaultName(MySpaceItemType type) {
    final defaultName = _generateUniqueDefaultName(type, null);
    _addRootItem(type, defaultName);
  }

  /// 添加子项目（使用默认名称）
  void _addChildItemWithDefaultName(MySpaceMenuItem parentItem, MySpaceItemType type) {
    final defaultName = _generateUniqueDefaultName(type, parentItem);
    final parentViewId = parentItem.view?.id;
    
    // 调试信息
    debugPrint('创建子项目: $defaultName, 父项目ID: $parentViewId, 父项目类型: ${parentItem.type}, 父项目名称: ${parentItem.name}');
    
    _createRealBackendEntity(type, defaultName, parentViewId);
  }

  /// 生成唯一的默认名称
  String _generateUniqueDefaultName(MySpaceItemType type, MySpaceMenuItem? parentItem) {
    final baseName = '未命名${_getTypeName(type)}';
    
    // 获取兄弟项目列表
    List<MySpaceMenuItem> siblings;
    if (parentItem != null) {
      siblings = parentItem.children;
    } else {
      siblings = _menuItems;
    }
    
    // 过滤出同类型的兄弟项目
    final sameTypeSiblings = siblings.where((item) => item.type == type).toList();
    
    // 检查基础名称是否已存在
    if (!sameTypeSiblings.any((item) => item.name == baseName)) {
      return baseName;
    }
    
    // 如果基础名称已存在，尝试添加数字后缀
    int counter = 2;
    String candidateName;
    do {
      candidateName = '$baseName $counter';
      counter++;
    } while (sameTypeSiblings.any((item) => item.name == candidateName) && counter <= 100);
    
    return candidateName;
  }

  /// 将AddItemType转换为MySpaceItemType
  MySpaceItemType _convertToMySpaceItemType(AddItemType type) {
    switch (type) {
      case AddItemType.folder:
        return MySpaceItemType.folder;
      case AddItemType.notebook:
        return MySpaceItemType.notebook;
      case AddItemType.note:
        return MySpaceItemType.note;
    }
  }



  /// 根据视图图标识别MySpace项目类型
  MySpaceItemType _identifyViewType(ViewPB view) {
    // 首先通过布局类型识别（最准确的方式）
    switch (view.layout) {
      case ViewLayoutPB.Folder:
        return MySpaceItemType.folder;
      case ViewLayoutPB.Notebook:
        return MySpaceItemType.notebook;
      case ViewLayoutPB.Document:
        // 文档类型需要进一步识别
        break;
      default:
        // 其他布局类型默认为笔记
        return MySpaceItemType.note;
    }
    
    // 对于Document布局，通过图标识别类型
    if (view.icon.value.isNotEmpty) {
      final icon = view.icon.value;
      if (icon.contains('📁') || icon.contains('folder')) {
        return MySpaceItemType.folder;
      } else if (icon.contains('📓') || icon.contains('notebook')) {
        return MySpaceItemType.notebook;
      }
    }
    
    // 通过名称模式识别
    final name = view.name.toLowerCase();
    if (name.contains('文件夹') || name.contains('folder')) {
      return MySpaceItemType.folder;
    } else if (name.contains('笔记本') || name.contains('notebook')) {
      return MySpaceItemType.notebook;
    }
    
    // 默认为笔记类型
    return MySpaceItemType.note;
  }

  /// 计算项目的深度层级
  int _calculateItemDepth(MySpaceMenuItem item) {
    int depth = 1; // 根级项目深度为1
    
    // 获取当前工作区ID
    final workspaceId = _getWorkspaceId();
    
    // 通过遍历菜单项列表找到父项目链
    String? currentParentId = item.view?.parentViewId;
    
    debugPrint('计算深度: ${item.view?.name} (ID: ${item.id})');
    debugPrint('  初始父ID: $currentParentId, 工作区ID: $workspaceId');
    
    // 如果 parentViewId 为空或者等于 workspaceId，则认为是根级项目
    while (currentParentId != null && 
           currentParentId.isNotEmpty && 
           currentParentId != workspaceId) {
      depth++;
      debugPrint('  当前深度: $depth, 查找父项目: $currentParentId');
      
      // 查找父项目
      MySpaceMenuItem? parentItem = _findItemById(_menuItems, currentParentId);
      
      if (parentItem?.view?.parentViewId != null) {
        currentParentId = parentItem!.view!.parentViewId;
        debugPrint('    找到父项目: ${parentItem.view?.name}, 其父ID: $currentParentId');
      } else {
        debugPrint('    未找到父项目，停止计算');
        break;
      }
      
      // 防止无限循环
      if (depth > _maxFolderDepth + 2) {
        debugPrint('    达到最大深度限制，停止计算');
        break;
      }
    }
    
    debugPrint('  最终深度: $depth');
    return depth;
  }

  /// 获取当前工作区ID
  String? _getWorkspaceId() {
    try {
      // 尝试从 UserWorkspaceBloc 获取
      final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
      return userWorkspaceBloc.state.currentWorkspace?.workspaceId;
    } catch (e) {
      debugPrint('无法获取工作区ID: $e');
      return null;
    }
  }

  /// 通过ID查找菜单项
  MySpaceMenuItem? _findItemById(List<MySpaceMenuItem> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
      // 递归查找子项目
      final found = _findItemById(item.children, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// 获取允许在指定父类型下创建的子项目类型
  List<MySpaceItemType> _getAllowedChildTypes(MySpaceItemType parentType, {MySpaceMenuItem? parentItem}) {
    // 检查深度限制 - 只有当新子项目会超过最大深度时才阻止创建
    if (parentItem != null) {
      final currentDepth = _calculateItemDepth(parentItem);
      final newChildDepth = currentDepth + 1; // 新子项目的深度
      if (newChildDepth > _maxFolderDepth) {
        debugPrint('⚠️  无法创建子项目：新项目深度 ($newChildDepth) 将超过最大深度限制 ($_maxFolderDepth 层)，当前父项目深度：$currentDepth');
        // 可以考虑显示用户提示
        _showDepthLimitWarning();
        return []; // 不允许创建任何子项目
      }
      debugPrint('✅  允许创建子项目：当前父项目深度 $currentDepth，新子项目深度 $newChildDepth，限制 $_maxFolderDepth');
    }
    
    switch (parentType) {
      case MySpaceItemType.folder:
        // 文件夹可以创建：文件夹、笔记本、笔记
        return [MySpaceItemType.folder, MySpaceItemType.notebook, MySpaceItemType.note];
      case MySpaceItemType.notebook:
        // 笔记本只能创建：笔记
        return [MySpaceItemType.note];
      case MySpaceItemType.note:
        // 笔记不能创建任何子项目
        return [];
    }
  }

  /// 显示深度限制警告
  void _showDepthLimitWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法创建更多子文件夹：已达到最大深度限制（$_maxFolderDepth 层）'),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// 设置视图图标
  Future<void> _setViewIcon(ViewPB view, String iconData) async {
    try {
      final emojiIcon = EmojiIconData.emoji(iconData);
      
      final result = await ViewBackendService.updateViewIcon(
        view: view,
        viewIcon: emojiIcon,
      );
      result.fold(
        (success) {
          // 图标设置成功
        },
        (error) {
          // 图标设置失败，但不影响主要功能
          debugPrint('设置图标失败: ${error.msg}');
        },
      );
    } catch (e) {
      debugPrint('设置图标异常: $e');
    }
  }

  /// 为新创建的根级视图设置图标
  Future<void> _setIconForNewRootView(String viewName, String iconData) async {
    try {
      // 获取当前私有区域的视图列表
      final state = context.read<SidebarSectionsBloc>().state;
      final privateSection = state.section;
      
      // privateSection不会为null，因为我们已经获取到了state.section
      {
        // 查找刚创建的视图
        final newView = privateSection.publicViews
            .where((view) => view.name == viewName)
            .lastOrNull;
            
        if (newView != null) {
          await _setViewIcon(newView, iconData);
          // 刷新菜单以显示新图标
          await _syncMenuItemsFromBloc();
        }
      }
    } catch (e) {
      debugPrint('为根级视图设置图标异常: $e');
    }
  }

  /// 统一的后端实体创建方法
  Future<void> _createRealBackendEntity(MySpaceItemType type, String name, String? parentViewId) async {
    try {
      ViewLayoutPB layoutType;
      String? iconData;
      
      // 调试信息
      debugPrint('创建后端实体: 类型=$type, 名称=$name, 父视图ID=$parentViewId');
      
      // 根据类型确定布局和图标
      switch (type) {
        case MySpaceItemType.folder:
          // 文件夹使用专门的文件夹布局类型
          layoutType = ViewLayoutPB.Folder;
          iconData = '📁'; // 文件夹图标
          break;
        case MySpaceItemType.notebook:
          // 笔记本使用专门的笔记本布局类型
          layoutType = ViewLayoutPB.Notebook;
          iconData = '📓'; // 笔记本图标
          break;
        case MySpaceItemType.note:
          // 笔记使用文档布局
          layoutType = ViewLayoutPB.Document;
          iconData = null; // 使用默认文档图标
          break;
      }

      if (parentViewId != null) {
        // 创建子项目
        final result = await ViewBackendService.createView(
          layoutType: layoutType,
          parentViewId: parentViewId,
          name: name,
          openAfterCreate: false,
          section: ViewSectionPB.Private, // 使用私有区域
        );
        
        result.fold(
          (newView) async {
            debugPrint('子项目创建成功: ID=${newView.id}, 名称=${newView.name}, 父ID=${newView.parentViewId}');
            
            // 创建成功后设置图标
            if (iconData != null) {
              await _setViewIcon(newView, iconData);
            }
            // 显示提示并同步菜单
            showMessageToast('已创建${_getTypeName(type)}: $name', context: context);
            
            // 立即将新创建的项目添加到UI中（临时解决方案）
            _addNewChildItemToUI(newView, parentViewId);
            
            // 确保父项目保持展开状态
            _ensureParentExpanded(parentViewId);
            
            // 对于深层嵌套的项目，需要特别处理展开逻辑
            debugPrint('新建子项目成功，父项目ID: $parentViewId');
            debugPrint('新创建的子项目详情: ID=${newView.id}, 名称=${newView.name}, 父ID=${newView.parentViewId}');
            
            // 注意：SidebarSectionsBloc 会通过 ViewListener 自动接收到视图更新通知
            // 我们依赖现有的同步机制，不需要手动触发刷新
            debugPrint('依赖 ViewListener 自动同步新创建的项目到 SidebarSectionsBloc');
            
            // 安排多次延迟同步，确保列表更新，并保持父项目展开状态
            _scheduleMultipleSyncs(parentViewId);
          },
          (error) {
            debugPrint('子项目创建失败: ${error.msg}');
            showMessageToast('创建${_getTypeName(type)}失败: ${error.msg}', context: context);
          },
        );
      } else {
        // 创建根级项目 - 暂时使用现有机制，后续可以优化
        context.read<SidebarSectionsBloc>().add(
          SidebarSectionsEvent.createRootViewInSection(
            name: name,
            index: 0,
            viewSection: ViewSectionPB.Private, // 使用私有区域，对应"我的空间"
          ),
        );
        
        // 为根级项目设置图标（延迟执行，等待视图创建完成）
        if (iconData != null) {
          Future.delayed(const Duration(milliseconds: 500), () async {
            // 查找刚创建的视图并设置图标
            await _setIconForNewRootView(name, iconData!);
          });
        }
        
        showMessageToast('已创建${_getTypeName(type)}: $name', context: context);
        
        // 安排多次延迟同步，确保列表更新
        _scheduleMultipleSyncs();
      }
    } catch (e) {
      showMessageToast('创建${_getTypeName(type)}失败: $e', context: context);
    }
  }





  /// 打开已存在的文档 - 复用"个人的"主菜单的打开逻辑
  void _openExistingDocument(MySpaceMenuItem item) async {
    try {
      // 获取实际的ViewPB对象
      final viewResult = await ViewBackendService.getView(item.id);
      
      await viewResult.fold(
        (view) async {
          // 成功获取到ViewPB，打开文档
          final plugin = view.plugin();
          
          // 使用TabsBloc打开插件
          getIt<TabsBloc>().add(
            TabsEvent.openPlugin(
              plugin: plugin,
              view: view,
              setLatest: true,
            ),
          );
          
          showMessageToast('已打开笔记: ${item.name}', context: context);
        },
        (error) {
          // 获取ViewPB失败，可能是UI-only项目或已删除的文档
          showMessageToast('无法打开笔记: ${item.name} - ${error.msg}', context: context);
        },
      );
    } catch (e) {
      showMessageToast('打开笔记失败: $e', context: context);
    }
  }

  /// 从SidebarSectionsBloc同步菜单项（智能合并，保持UI状态）
  Future<void> _syncMenuItemsFromBloc() async {
    if (!mounted) return;
    
    // 清理过期的缓存
    _cleanExpiredRenameCache();
    _cleanExpiredRecentlyCreatedCache();
    
    try {
      final sidebarSectionsBloc = context.read<SidebarSectionsBloc>();
      final privateViews = sidebarSectionsBloc.state.section.privateViews;
      
      // 获取所有视图（包括子视图）以确保数据完整
      final allViewsResult = await ViewBackendService.getAllViews();
      List<ViewPB> allViews = [];
      allViewsResult.fold(
        (views) => allViews = views.items,
        (error) => debugPrint('获取所有视图失败: $error'),
      );
      
      // 过滤出私有视图（非公共视图）
      final completePrivateViews = allViews.where((view) => 
        view.parentViewId.isNotEmpty || privateViews.any((pv) => pv.id == view.id)
      ).toList();
      
      // 调试信息
      debugPrint('同步菜单项: SidebarSectionsBloc提供${privateViews.length}个根级视图, getAllViews获取${allViews.length}个总视图, 过滤后${completePrivateViews.length}个私有视图');
      for (final view in completePrivateViews) {
        debugPrint('  视图: ${view.name} (ID: ${view.id}, 父ID: ${view.parentViewId})');
      }
      
      // 检查是否缺少深层嵌套的视图
      _checkForMissingDeepViews(completePrivateViews);
      
      setState(() {
        final oldCount = _menuItems.length;
        final oldExpandedStates = _collectExpandedStates(_menuItems);
        _menuItems = _mergeViewsWithLocalState(completePrivateViews, _menuItems);
        _restoreExpandedStates(_menuItems, oldExpandedStates);
        debugPrint('菜单项更新: $oldCount -> ${_menuItems.length}');
      });
    } catch (e) {
      // 如果context还未准备好，忽略错误
      // 会在BlocListener中重新尝试
      debugPrint('同步菜单项异常: $e');
    }
  }

  /// 收集所有项目的展开状态
  Map<String, bool> _collectExpandedStates(List<MySpaceMenuItem> items) {
    final states = <String, bool>{};
    for (final item in items) {
      states[item.id] = item.isExpanded;
      if (item.children.isNotEmpty) {
        states.addAll(_collectExpandedStates(item.children));
      }
    }
    return states;
  }

  /// 恢复项目的展开状态
  void _restoreExpandedStates(List<MySpaceMenuItem> items, Map<String, bool> states) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (states.containsKey(item.id)) {
        items[i] = item.copyWith(isExpanded: states[item.id]!);
      }
      if (item.children.isNotEmpty) {
        _restoreExpandedStates(items[i].children, states);
      }
    }
  }

  /// 安排多次延迟同步，确保新创建的项目显示在列表中
  void _scheduleMultipleSyncs([String? parentIdToKeepExpanded]) {
    if (!mounted) return;
    
    // 第一次延迟同步 - 200ms（更快响应）
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (mounted) {
        await _syncMenuItemsFromBloc();
        if (parentIdToKeepExpanded != null) {
          _ensureParentExpanded(parentIdToKeepExpanded);
        }
      }
    });
    
    // 第二次延迟同步 - 500ms
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        await _syncMenuItemsFromBloc();
        if (parentIdToKeepExpanded != null) {
          _ensureParentExpanded(parentIdToKeepExpanded);
        }
      }
    });
    
    // 第三次延迟同步 - 1000ms（确保所有异步操作完成）
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (mounted) {
        await _syncMenuItemsFromBloc();
        if (parentIdToKeepExpanded != null) {
          _ensureParentExpanded(parentIdToKeepExpanded);
        }
        
        // 清理无效的视图祖先缓存，防止View not found错误
        _cleanupInvalidViewAncestorCache();
        
        // 对于深层嵌套的情况，强制重新加载数据
        if (parentIdToKeepExpanded != null) {
          _forceReloadDeepViews(parentIdToKeepExpanded);
        }
      }
    });
    
    // 第四次延迟同步 - 2000ms（最终确认）
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _syncMenuItemsFromBloc();
        if (parentIdToKeepExpanded != null) {
          _ensureParentExpanded(parentIdToKeepExpanded);
        }
      }
    });
  }

  /// 确保指定的父项目保持展开状态
  void _ensureParentExpanded(String parentId) {
    if (!mounted) return;
    
    setState(() {
      final expanded = _expandParentRecursive(_menuItems, parentId);
      if (!expanded) {
        debugPrint('无法在根级菜单中找到项目 $parentId，尝试展开其祖先路径');
        _expandAncestorPath(parentId);
      }
    });
    
    debugPrint('确保父项目展开: $parentId');
  }

  /// 递归展开指定的父项目
  bool _expandParentRecursive(List<MySpaceMenuItem> items, String targetId) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == targetId) {
        items[i] = items[i].copyWith(isExpanded: true);
        return true;
      }
      if (_expandParentRecursive(items[i].children, targetId)) {
        // 如果在子项目中找到了目标，也要展开当前项目
        items[i] = items[i].copyWith(isExpanded: true);
        return true;
      }
    }
    return false;
  }

  /// 展开祖先路径，确保深层嵌套的项目能被找到和展开
  void _expandAncestorPath(String targetId) {
    // 从当前菜单项中找到目标项目及其祖先路径
    final ancestorPath = _findAncestorPath(_menuItems, targetId, []);
    
    if (ancestorPath.isNotEmpty) {
      debugPrint('找到祖先路径: ${ancestorPath.map((item) => item.name).join(' -> ')}');
      
      // 展开祖先路径中的所有项目
      for (final ancestor in ancestorPath) {
        _expandParentRecursive(_menuItems, ancestor.id);
        debugPrint('展开祖先项目: ${ancestor.name} (ID: ${ancestor.id})');
      }
    } else {
      debugPrint('未找到项目 $targetId 的祖先路径');
    }
  }

  /// 查找项目的祖先路径
  List<MySpaceMenuItem> _findAncestorPath(List<MySpaceMenuItem> items, String targetId, List<MySpaceMenuItem> currentPath) {
    for (final item in items) {
      final newPath = [...currentPath, item];
      
      if (item.id == targetId) {
        // 找到目标项目，返回祖先路径（不包括目标项目本身）
        return currentPath;
      }
      
      // 在子项目中递归查找
      final result = _findAncestorPath(item.children, targetId, newPath);
      if (result.isNotEmpty) {
        return result;
      }
    }
    
    return [];
  }

  /// 展平视图列表，包含所有子视图
  List<ViewPB> _flattenViewsWithChildren(List<ViewPB> views) {
    final result = <ViewPB>[];
    
    void addViewRecursively(ViewPB view) {
      result.add(view);
      for (final child in view.childViews) {
        addViewRecursively(child);
      }
    }
    
    for (final view in views) {
      addViewRecursively(view);
    }
    
    return result;
  }

  /// 智能合并后端数据与本地状态，保持UI层的修改
  List<MySpaceMenuItem> _mergeViewsWithLocalState(
    List<ViewPB> backendViews,
    List<MySpaceMenuItem> localItems,
  ) {
    final result = <MySpaceMenuItem>[];
    
    // 先展平所有视图（包括子视图）
    final allViews = _flattenViewsWithChildren(backendViews);
    final validBackendViews = _filterValidViews(allViews);
    
    // 调试信息
    debugPrint('合并视图数据: ${backendViews.length} -> ${allViews.length} 总视图 -> ${validBackendViews.length} 有效视图');
    
    // 详细显示所有视图的层级关系
    _debugViewHierarchy(validBackendViews);
    
    final backendViewsMap = <String, ViewPB>{
      for (final view in validBackendViews) view.id: view,
    };
    
    // 清理本地状态中的无效项目（防止缓存问题）
    final validLocalItems = localItems.where((item) => 
      // 保留UI-only项目或后端存在的项目
      _isUIOnlyItem(item) || backendViewsMap.containsKey(item.id)
    ).toList();
    
    final localItemsMap = <String, MySpaceMenuItem>{
      for (final item in validLocalItems) item.id: item,
    };
    
    debugPrint('清理本地状态: ${localItems.length} -> ${validLocalItems.length} 有效项目');

    // 1. 只处理根级视图（没有父项目的视图）
    final rootViews = validBackendViews.where((view) => 
      view.parentViewId.isEmpty || 
      !validBackendViews.any((v) => v.id == view.parentViewId)
    ).toList();
    
    debugPrint('识别根级视图: ${rootViews.length}/${validBackendViews.length}');
    for (final rootView in rootViews) {
      debugPrint('  根级视图: ${rootView.name} (ID: ${rootView.id})');
    }
    
    // 处理根级视图并构建完整的层级结构
    for (final view in rootViews) {
      final existingLocal = localItemsMap[view.id];
      
      if (existingLocal != null) {
        // 如果本地已存在，保持本地的UI状态（如展开状态），但同步后端的数据
        // 重要：需要重新构建层级关系以包含新的子项目
        final menuItem = _convertViewToMenuItem(view);
        final updatedItem = _buildHierarchicalItem(menuItem, validBackendViews, depth: 1);
        
        // 保持原有的展开状态和UI状态
        result.add(updatedItem.copyWith(
          isExpanded: existingLocal.isExpanded, // 保持展开状态
        ));
        
        // 调试信息
        debugPrint('保持项目状态: ${updatedItem.name} (展开: ${updatedItem.isExpanded}, 子项目数: ${updatedItem.children.length})');
      } else {
        // 如果本地不存在，创建新项目并构建层级关系
        final menuItem = _convertViewToMenuItem(view);
        final newItem = _buildHierarchicalItem(menuItem, validBackendViews, depth: 1);
        result.add(newItem);
        
        // 调试信息
        debugPrint('创建新项目: ${newItem.name} (子项目数: ${newItem.children.length})');
      }
    }

    // 2. 保留本地新增但尚未同步到后端的项目（仅限UI-only项目）
    for (final localItem in validLocalItems) {
      if (!backendViewsMap.containsKey(localItem.id) && 
          _isUIOnlyItem(localItem)) {
        result.add(localItem);
        debugPrint('保留UI-only项目: ${localItem.name}');
      }
    }

    // 3. 最终调试信息
    debugPrint('合并完成: 最终项目数: ${result.length}');
    for (final item in result) {
      debugPrint('  根项目: ${item.name} (子项目数: ${item.children.length})');
      _debugChildrenRecursive(item.children, depth: 1);
    }
    
    return result;
  }

  /// 递归显示子项目的调试信息
  void _debugChildrenRecursive(List<MySpaceMenuItem> children, {int depth = 1}) {
    final indent = '  ' * (depth + 1);
    for (final child in children) {
      debugPrint('$indent子项目: ${child.name} (ID: ${child.id}, 子项目数: ${child.children.length})');
      if (child.children.isNotEmpty) {
        _debugChildrenRecursive(child.children, depth: depth + 1);
      }
    }
  }

  /// 构建层级关系的菜单项
  MySpaceMenuItem _buildHierarchicalItem(MySpaceMenuItem item, List<ViewPB> allViews, {int depth = 1}) {
    // 检查深度限制 - 只有当深度超过限制时才停止构建
    if (depth > _maxFolderDepth) {
      debugPrint('⚠️  达到最大深度限制 ($_maxFolderDepth 层): ${item.name} (当前深度: $depth)');
      return item; // 不再构建子项目
    }
    
    // 查找该项目的子项目
    final childViews = allViews.where((view) => 
      view.parentViewId == item.id && view.id != item.id
    ).toList();
    
    // 调试信息
    if (childViews.isNotEmpty) {
      debugPrint('构建层级: ${item.name} 有 ${childViews.length} 个子项目 (深度: $depth)');
      for (final child in childViews) {
        debugPrint('  子项目: ${child.name} (ID: ${child.id})');
      }
    }
    
    if (childViews.isEmpty) {
      return item;
    }
    
    // 按名称排序子项目，确保显示顺序一致
    childViews.sort((a, b) => a.name.compareTo(b.name));
    
    final childItems = childViews.map((childView) {
      final childItem = _convertViewToMenuItem(childView);
      return _buildHierarchicalItem(childItem, allViews, depth: depth + 1);
    }).toList();
    
    return item.copyWith(children: childItems);
  }

  /// 判断是否为仅UI层的项目（还未同步到后端）
  bool _isUIOnlyItem(MySpaceMenuItem item) {
    // 1. 如果是文件夹或笔记本类型，且ID是时间戳格式，说明是UI层创建的
    if (item.type == MySpaceItemType.folder || item.type == MySpaceItemType.notebook) {
      // 检查ID是否为数字格式的时间戳（UI层生成的ID格式）
      if (RegExp(r'^\d+$').hasMatch(item.id)) {
        return true;
      }
    }
    
    // 2. 检查是否是最近创建的视图（30秒内创建的）
    final createdTime = _recentlyCreatedViews[item.id];
    if (createdTime != null) {
      final now = DateTime.now();
      final isRecent = now.difference(createdTime).inSeconds < 30;
      if (isRecent) {
        debugPrint('识别为最近创建的视图: ${item.name} (${now.difference(createdTime).inSeconds}秒前)');
        return true;
      }
      // 注意：不在这里清理缓存，由定期清理方法处理
    }
    
    // 笔记类型应该都有对应的ViewPB，如果后端没有则可能已被删除
    return false;
  }

  /// 清理无效的视图祖先缓存，防止View not found错误
  void _cleanupInvalidViewAncestorCache() {
    try {
      // 获取当前有效的视图ID列表
      final validViewIds = <String>{};
      void collectValidIds(List<MySpaceMenuItem> items) {
        for (final item in items) {
          if (item.view != null) {
            validViewIds.add(item.id);
          }
          collectValidIds(item.children);
        }
      }
      collectValidIds(_menuItems);
      
      debugPrint('清理视图祖先缓存: 当前有效视图数量: ${validViewIds.length}');
      
      // 这里可以添加清理ViewAncestorCache的逻辑
      // 由于ViewAncestorCache是一个独立的服务，我们通过获取实例来清理
      // 注意：这需要ViewAncestorCache提供清理方法
      
    } catch (e) {
      debugPrint('清理视图祖先缓存时发生错误: $e');
    }
  }

  /// 强制重新加载深层视图数据
  void _forceReloadDeepViews(String parentId) {
    try {
      debugPrint('强制重新加载深层视图数据，父项目ID: $parentId');
      
      // 强制SidebarSectionsBloc重新加载数据
      _forceReloadSidebarData();
      
      // 对于深层嵌套的情况，确保祖先路径都被展开
      _ensureAncestorPathExpanded(parentId);
      
      debugPrint('已处理深层视图展开逻辑');
    } catch (e) {
      debugPrint('强制重新加载深层视图数据时发生错误: $e');
    }
  }

  /// 强制SidebarSectionsBloc重新加载数据
  void _forceReloadSidebarData() {
    try {
      // 强制重新加载数据
      // 作为临时解决方案，我们使用一个延迟来确保后端数据已经更新
      debugPrint('请求SidebarSectionsBloc强制刷新数据');
      
      // 添加一个更长的延迟，等待后端数据完全同步
      Future.delayed(const Duration(milliseconds: 3000), () async {
        if (mounted) {
          debugPrint('执行最终数据同步检查');
          await _syncMenuItemsFromBloc();
        }
      });
      
    } catch (e) {
      debugPrint('强制重新加载SidebarData时发生错误: $e');
    }
  }

  /// 立即将新创建的子项目添加到UI中
  void _addNewChildItemToUI(ViewPB newView, String parentViewId) {
    try {
      debugPrint('立即添加新子项目到UI: ${newView.name} (ID: ${newView.id}, 父ID: $parentViewId)');
      
      // 将新创建的视图添加到最近创建缓存中
      _recentlyCreatedViews[newView.id] = DateTime.now();
      debugPrint('将新视图添加到最近创建缓存: ${newView.id}');
      
      setState(() {
        // 将ViewPB转换为MySpaceMenuItem
        final newMenuItem = _convertViewToMenuItem(newView);
        
        // 递归查找父项目并添加子项目
        bool added = _addChildToParentRecursive(_menuItems, parentViewId, newMenuItem);
        
        if (added) {
          debugPrint('成功将新子项目添加到父项目 $parentViewId');
        } else {
          debugPrint('未找到父项目 $parentViewId，无法添加子项目');
        }
      });
      
    } catch (e) {
      debugPrint('添加新子项目到UI时发生错误: $e');
    }
  }

  /// 递归查找父项目并添加子项目
  bool _addChildToParentRecursive(List<MySpaceMenuItem> items, String parentId, MySpaceMenuItem childItem) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      
      if (item.id == parentId) {
        // 找到父项目，检查子项目是否已存在
        final existingChildIndex = item.children.indexWhere((child) => child.id == childItem.id);
        
        if (existingChildIndex == -1) {
          // 子项目不存在，添加到子项目列表
          final updatedChildren = [...item.children, childItem];
          items[i] = item.copyWith(children: updatedChildren, isExpanded: true);
          debugPrint('已将子项目 ${childItem.name} 添加到父项目 ${item.name}');
          return true;
        } else {
          // 子项目已存在，更新现有子项目
          final updatedChildren = [...item.children];
          updatedChildren[existingChildIndex] = childItem;
          items[i] = item.copyWith(children: updatedChildren, isExpanded: true);
          debugPrint('已更新父项目 ${item.name} 中的子项目 ${childItem.name}');
          return true;
        }
      } else if (item.children.isNotEmpty) {
        // 递归查找子项目
        if (_addChildToParentRecursive(item.children, parentId, childItem)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// 确保祖先路径都被展开
  void _ensureAncestorPathExpanded(String targetId) {
    final ancestorPath = _findAncestorPath(_menuItems, targetId, []);
    
    if (ancestorPath.isNotEmpty) {
      debugPrint('展开祖先路径以确保深层项目可见: ${ancestorPath.map((item) => item.name).join(' -> ')}');
      
      // 展开所有祖先项目
      for (final ancestor in ancestorPath) {
        _expandParentRecursive(_menuItems, ancestor.id);
        debugPrint('  展开祖先: ${ancestor.name} (ID: ${ancestor.id})');
      }
      
      // 最后展开目标项目本身
      _expandParentRecursive(_menuItems, targetId);
      debugPrint('  展开目标项目: $targetId');
    } else {
      debugPrint('未找到目标项目 $targetId 的祖先路径');
    }
  }

  /// 检查是否缺少深层嵌套的视图
  void _checkForMissingDeepViews(List<ViewPB> views) {
    try {
      // 构建父子关系映射
      final parentChildMap = <String, List<ViewPB>>{};
      final allViewIds = <String>{};
      
      for (final view in views) {
        allViewIds.add(view.id);
        final parentId = view.parentViewId;
        if (parentId.isNotEmpty) {
          parentChildMap.putIfAbsent(parentId, () => []).add(view);
        }
      }
      
      debugPrint('深层嵌套检查: 总视图数=${views.length}, 父子关系=${parentChildMap.length}');
      
      // 检查是否有父项目在视图列表中但子项目缺失
      for (final entry in parentChildMap.entries) {
        final parentId = entry.key;
        final children = entry.value;
        
        if (allViewIds.contains(parentId)) {
          debugPrint('  父项目 $parentId 有 ${children.length} 个子项目:');
          for (final child in children) {
            debugPrint('    子项目: ${child.name} (ID: ${child.id})');
          }
        } else {
          debugPrint('  ⚠️  父项目 $parentId 不在视图列表中，但有 ${children.length} 个子项目');
        }
      }
      
      // 检查三级嵌套
      var deepNestingCount = 0;
      for (final view in views) {
        if (view.parentViewId.isNotEmpty && parentChildMap.containsKey(view.id)) {
          final grandParentId = _findParentOfParent(views, view.id);
          if (grandParentId != null) {
            deepNestingCount++;
            debugPrint('  发现三级嵌套: ${view.name} (ID: ${view.id}) -> 父: ${view.parentViewId} -> 祖父: $grandParentId');
          }
        }
      }
      
      debugPrint('深层嵌套检查完成: 发现 $deepNestingCount 个三级嵌套项目');
      
    } catch (e) {
      debugPrint('检查深层嵌套视图时发生错误: $e');
    }
  }
  
  /// 查找父项目的父项目ID
  String? _findParentOfParent(List<ViewPB> views, String viewId) {
    // 找到当前视图的父项目
    final currentView = views.firstWhere((v) => v.id == viewId, orElse: () => ViewPB());
    if (currentView.parentViewId.isEmpty) return null;
    
    // 找到父项目的父项目
    final parentView = views.firstWhere((v) => v.id == currentView.parentViewId, orElse: () => ViewPB());
    if (parentView.parentViewId.isEmpty) return null;
    
    return parentView.parentViewId;
  }

  /// 调试显示视图层级关系
  void _debugViewHierarchy(List<ViewPB> views) {
    try {
      debugPrint('=== 视图层级关系详情 ===');
      
      // 按层级分组
      final workspaceId = _getWorkspaceId();
      // 根级视图：parentViewId 为空或者等于 workspaceId
      final rootViews = views.where((v) => v.parentViewId.isEmpty || v.parentViewId == workspaceId).toList();
      final childViews = views.where((v) => v.parentViewId.isNotEmpty && v.parentViewId != workspaceId).toList();
      
      debugPrint('根级视图 (${rootViews.length}个):');
      for (final view in rootViews) {
        debugPrint('  📁 ${view.name} (ID: ${view.id})');
        _debugViewChildren(views, view.id, 1);
      }
      
      // 检查孤儿视图（父项目不存在的子视图）
      final orphanViews = <ViewPB>[];
      for (final child in childViews) {
        final hasParent = views.any((v) => v.id == child.parentViewId);
        if (!hasParent) {
          orphanViews.add(child);
        }
      }
      
      if (orphanViews.isNotEmpty) {
        debugPrint('⚠️  孤儿视图 (${orphanViews.length}个):');
        for (final orphan in orphanViews) {
          debugPrint('  🔴 ${orphan.name} (ID: ${orphan.id}, 父ID: ${orphan.parentViewId})');
        }
      }
      
      debugPrint('=== 层级关系详情结束 ===');
    } catch (e) {
      debugPrint('调试视图层级关系时发生错误: $e');
    }
  }

  /// 递归显示子视图
  void _debugViewChildren(List<ViewPB> allViews, String parentId, int level) {
    final children = allViews.where((v) => v.parentViewId == parentId).toList();
    final indent = '  ' * level;
    
    for (final child in children) {
      final icon = level == 1 ? '📂' : (level == 2 ? '📄' : '🔸');
      
      // 显示深度警告
      if (level > _maxFolderDepth) {
        debugPrint('$indent⚠️  ${child.name} (ID: ${child.id}) - 超过最大深度限制 (第${level}层)');
      } else {
        debugPrint('$indent$icon ${child.name} (ID: ${child.id}) - 第${level}层');
      }
      
      // 递归显示更深层的子项目，但如果超过限制则显示警告
      if (level <= _maxFolderDepth) {
        _debugViewChildren(allViews, child.id, level + 1);
      } else {
        // 检查是否还有更深层的子项目
        final deepChildren = allViews.where((v) => v.parentViewId == child.id).toList();
        if (deepChildren.isNotEmpty) {
          debugPrint('$indent  ⚠️  此项目有 ${deepChildren.length} 个子项目被深度限制隐藏');
        }
      }
    }
  }


  
  /// 过滤有效的视图，去除重复和无效项
  List<ViewPB> _filterValidViews(List<ViewPB> views) {
    final seenIds = <String>{};
    final validViews = <ViewPB>[];
    
    for (final view in views) {
      // 检查是否重复
      if (seenIds.contains(view.id)) {
        continue;
      }
      
      // 检查是否有效（有id有名字）
      if (view.id.isNotEmpty && view.name.isNotEmpty) {
        seenIds.add(view.id);
        validViews.add(view);
      }
    }
    
    return validViews;
  }

  /// 将单个ViewPB转换为MySpaceMenuItem
  MySpaceMenuItem _convertViewToMenuItem(ViewPB view) {
    // 根据ViewPB的名称和布局推断类型
    MySpaceItemType itemType = _inferViewType(view);
    
    // 优先使用重命名缓存中的名称，如果没有则使用view的名称
    final displayName = _getFromRenameCache(view.id) ?? view.name;

    return MySpaceMenuItem(
      id: view.id,
      name: displayName,
      icon: _getTypeEmoji(itemType),
      type: itemType,
      children: [], // 暂不处理子项目，后续可根据需要扩展
      isExpanded: false,
      view: view, // 添加关联的视图对象
    );
  }

  /// 推断ViewPB的类型
  MySpaceItemType _inferViewType(ViewPB view) {
    // 首先通过布局类型识别（最准确的方式）
    switch (view.layout) {
      case ViewLayoutPB.Folder:
        return MySpaceItemType.folder;
      case ViewLayoutPB.Notebook:
        return MySpaceItemType.notebook;
      case ViewLayoutPB.Document:
        // 文档类型需要进一步识别
        break;
      default:
        // 其他布局类型默认为笔记
        return MySpaceItemType.note;
    }
    
    // 对于Document布局，首先基于名称模式推断类型
    final name = view.name.toLowerCase();
    
    if (name.contains('文件夹') || name.contains('folder')) {
      return MySpaceItemType.folder;
    } else if (name.contains('笔记本') || name.contains('notebook')) {
      return MySpaceItemType.notebook;
    }
    
    // 然后基于是否有子项目判断
    // 如果有子项目且名称不明确，优先考虑为容器类型
    if (view.childViews.isNotEmpty) {
      // 有子项目的文档，可能是文件夹或笔记本
      return name.contains('未命名文件夹') ? MySpaceItemType.folder : MySpaceItemType.notebook;
    }
    
    // 默认为笔记类型
    return MySpaceItemType.note;
  }

  /// 检查两个privateViews列表是否相等
  bool _isPrivateViewsEqual(List<ViewPB> newViews, List<ViewPB> oldViews) {
    // 先过滤有效视图，再比较
    final filteredNewViews = _filterValidViews(newViews);
    final filteredOldViews = _filterValidViews(oldViews);
    
    if (filteredNewViews.length != filteredOldViews.length) {
      return false;
    }
    
    // 使用Set进行比较，避免顺序影响
    final newViewsSet = filteredNewViews.map((v) => '${v.id}:${v.name}:${v.layout}').toSet();
    final oldViewsSet = filteredOldViews.map((v) => '${v.id}:${v.name}:${v.layout}').toSet();
    
    return newViewsSet.length == oldViewsSet.length && 
           newViewsSet.every((item) => oldViewsSet.contains(item));
  }

  /// 清理重复的私有视图
  // Future<void> _cleanupDuplicateViews() async {
  //   try {
  //     final result = await ViewBackendService.cleanupDuplicatePrivateViews();
  //     result.fold(
  //       (cleanedCount) {
  //         if (cleanedCount > 0) {
  //           showSnackBarMessage(
  //             context,
  //             '已清理 $cleanedCount 个重复项目',
  //             showCancel: false,
  //           );
  //           // 触发重新同步
  //           _syncMenuItemsFromBloc();
  //         } else {
  //           showSnackBarMessage(
  //             context,
  //             '没有发现重复项目',
  //             showCancel: false,
  //           );
  //         }
  //       },
  //       (error) {
  //         showSnackBarMessage(
  //           context,
  //           '清理失败: ${error.msg}',
  //           showCancel: false,
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     showSnackBarMessage(
  //       context,
  //       '清理失败: $e',
  //       showCancel: false,
  //     );
  //   }
  // }
}

