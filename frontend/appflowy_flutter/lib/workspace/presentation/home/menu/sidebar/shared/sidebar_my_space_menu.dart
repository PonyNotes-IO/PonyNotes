import 'package:appflowy/generated/flowy_svgs.g.dart';
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

// 原弹窗组件已移除，改为使用下拉菜单

/// 重命名项目对话框
class _RenameItemDialog extends StatefulWidget {
  final String currentName;
  final Function(String) onRename;

  const _RenameItemDialog({
    required this.currentName,
    required this.onRename,
  });

  @override
  State<_RenameItemDialog> createState() => _RenameItemDialogState();
}

class _RenameItemDialogState extends State<_RenameItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _nameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newName = _nameController.text.trim();
    final canConfirm = newName.isNotEmpty && newName != widget.currentName;
    if (canConfirm != _canConfirm) {
      setState(() {
        _canConfirm = canConfirm;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名项目'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: '项目名称',
          hintText: '请输入新的项目名称',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) => _canConfirm ? _onConfirm() : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _canConfirm ? _onConfirm : null,
          child: const Text('重命名'),
        ),
      ],
    );
  }

  void _onConfirm() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != widget.currentName) {
      widget.onRename(newName);
      Navigator.of(context).pop();
    }
  }
}

/// 我的空间菜单组件
class SidebarMySpaceMenu extends StatefulWidget {
  const SidebarMySpaceMenu({super.key});

  @override
  State<SidebarMySpaceMenu> createState() => _SidebarMySpaceMenuState();
}

class _SidebarMySpaceMenuState extends State<SidebarMySpaceMenu> {
  // 是否全部展开的状态（暂未使用）
  // bool _isAllExpanded = false;
  // 我的空间主菜单是否展开的状态
  bool _isMainMenuExpanded = true;
  
  // 我的空间菜单项列表 - 从SidebarSectionsBloc同步获取
  List<MySpaceMenuItem> _menuItems = <MySpaceMenuItem>[];
  
  // 保存上次的privateViews，用于检测数据变化，避免重复同步
  List<ViewPB> _lastPrivateViews = [];

  @override
  void initState() {
    super.initState();
    // 在下一帧同步菜单项，确保context已准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncMenuItemsFromBloc();
      }
    });
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
          if (kDebugMode) // 只在调试模式下显示
            GestureDetector(
              onTap: _cleanupDuplicateViews,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.orange.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.cleaning_services,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
            ),
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
                // 名称
                Expanded(
                  child: GestureDetector(
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
    
    final allowedChildTypes = _getAllowedChildTypes(parentType);
    
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
  //   }
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
    showDialog(
      context: context,
      builder: (context) => _RenameItemDialog(
        currentName: item.name,
        onRename: (newName) {
          _renameItem(item, newName);
        },
      ),
    );
  }

  /// 执行重命名操作
  void _renameItem(MySpaceMenuItem item, String newName) async {
    // 先更新UI（提供即时反馈）
    final oldName = item.name;
    setState(() {
      _renameItemRecursive(_menuItems, item.id, newName);
    });

    try {
      // 调用后端API进行真实重命名 - 现在所有类型都需要重命名后端实体
      if (item.view != null) {
        // 如果有关联的ViewPB，说明是真实的后端实体，需要调用重命名API
        final result = await ViewBackendService.updateView(
          viewId: item.id,
          name: newName,
        );
        
        result.fold(
          (success) {
            // 重命名成功，显示提示
            showMessageToast('已重命名为: $newName', context: context);
            // 同步菜单项以确保UI与后端一致
            _syncMenuItemsFromBloc();
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
        // 如果没有关联的ViewPB，说明是仅UI层的项目（不太可能出现在当前实现中）
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
    final defaultName = '未命名${_getTypeName(type)}';
    _addRootItem(type, defaultName);
  }

  /// 添加子项目（使用默认名称）
  void _addChildItemWithDefaultName(MySpaceMenuItem parentItem, MySpaceItemType type) {
    final defaultName = '未命名${_getTypeName(type)}';
    final parentViewId = parentItem.view?.id;
    
    // 调试信息
    debugPrint('创建子项目: $defaultName, 父项目ID: $parentViewId, 父项目类型: ${parentItem.type}, 父项目名称: ${parentItem.name}');
    
    _createRealBackendEntity(type, defaultName, parentViewId);
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

  /// 获取允许在指定父类型下创建的子项目类型
  List<MySpaceItemType> _getAllowedChildTypes(MySpaceItemType parentType) {
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
          _syncMenuItemsFromBloc();
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
      debugPrint('开始创建后端实体: 类型=$type, 名称=$name, 父视图ID=$parentViewId');
      
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
            _syncMenuItemsFromBloc();
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
  void _syncMenuItemsFromBloc() {
    if (!mounted) return;
    
    try {
      final sidebarSectionsBloc = context.read<SidebarSectionsBloc>();
      final privateViews = sidebarSectionsBloc.state.section.privateViews;
      
      // 调试信息
      debugPrint('同步菜单项: 共${privateViews.length}个后端视图');
      for (final view in privateViews) {
        debugPrint('  视图: ${view.name} (ID: ${view.id}, 父ID: ${view.parentViewId})');
      }
      
      setState(() {
        final oldCount = _menuItems.length;
        _menuItems = _mergeViewsWithLocalState(privateViews, _menuItems);
        debugPrint('菜单项更新: $oldCount -> ${_menuItems.length}');
      });
    } catch (e) {
      // 如果context还未准备好，忽略错误
      // 会在BlocListener中重新尝试
      debugPrint('同步菜单项异常: $e');
    }
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
    
    final backendViewsMap = <String, ViewPB>{
      for (final view in validBackendViews) view.id: view,
    };
    final localItemsMap = <String, MySpaceMenuItem>{
      for (final item in localItems) item.id: item,
    };

    // 1. 处理后端存在的项目（更新或保持现有状态）
    for (final view in validBackendViews) {
      final existingLocal = localItemsMap[view.id];
      
      if (existingLocal != null) {
        // 如果本地已存在，保持本地的UI状态（如展开状态），但同步后端的数据
        // 重要：需要重新构建层级关系以包含新的子项目
        final menuItem = _convertViewToMenuItem(view);
        final updatedItem = _buildHierarchicalItem(menuItem, validBackendViews);
        
        result.add(updatedItem.copyWith(
          isExpanded: existingLocal.isExpanded, // 保持展开状态
        ));
      } else {
        // 如果本地不存在，创建新项目并构建层级关系
        final menuItem = _convertViewToMenuItem(view);
        result.add(_buildHierarchicalItem(menuItem, validBackendViews));
      }
    }

    // 2. 保留本地新增但尚未同步到后端的项目（仅限UI-only项目）
    for (final localItem in localItems) {
      if (!backendViewsMap.containsKey(localItem.id) && 
          _isUIOnlyItem(localItem)) {
        result.add(localItem);
      }
    }

    // 3. 过滤掉已经作为子项目的项目，避免重复显示
    return _filterRootItems(result, validBackendViews);
  }

  /// 构建层级关系的菜单项
  MySpaceMenuItem _buildHierarchicalItem(MySpaceMenuItem item, List<ViewPB> allViews) {
    // 查找该项目的子项目
    final childViews = allViews.where((view) => 
      view.parentViewId == item.id && view.id != item.id
    ).toList();
    
    // 调试信息
    if (childViews.isNotEmpty) {
      debugPrint('构建层级: ${item.name} 有 ${childViews.length} 个子项目');
      for (final child in childViews) {
        debugPrint('  子项目: ${child.name} (ID: ${child.id})');
      }
    }
    
    if (childViews.isEmpty) {
      return item;
    }
    
    final childItems = childViews.map((childView) {
      final childItem = _convertViewToMenuItem(childView);
      return _buildHierarchicalItem(childItem, allViews);
    }).toList();
    
    return item.copyWith(children: childItems);
  }

  /// 过滤根级项目，移除已经作为子项目的项目
  List<MySpaceMenuItem> _filterRootItems(List<MySpaceMenuItem> items, List<ViewPB> allViews) {
    final childViewIds = <String>{};
    
    // 收集所有子视图的ID
    for (final view in allViews) {
      if (view.parentViewId.isNotEmpty && 
          allViews.any((parent) => parent.id == view.parentViewId)) {
        childViewIds.add(view.id);
      }
    }
    
    // 调试信息
    debugPrint('过滤根级项目: ${items.length} 项目 -> 子项目IDs: $childViewIds');
    
    // 只返回根级项目（不是其他项目子项目的项目）
    final rootItems = items.where((item) => !childViewIds.contains(item.id)).toList();
    debugPrint('过滤结果: ${rootItems.length} 根级项目');
    
    return rootItems;
  }

  /// 判断是否为仅UI层的项目（还未同步到后端）
  bool _isUIOnlyItem(MySpaceMenuItem item) {
    // 如果是文件夹或笔记本类型，且ID是时间戳格式，说明是UI层创建的
    if (item.type == MySpaceItemType.folder || item.type == MySpaceItemType.notebook) {
      // 检查ID是否为数字格式的时间戳（UI层生成的ID格式）
      return RegExp(r'^\d+$').hasMatch(item.id);
    }
    
    // 笔记类型应该都有对应的ViewPB，如果后端没有则可能已被删除
    return false;
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

    return MySpaceMenuItem(
      id: view.id,
      name: view.name,
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
  Future<void> _cleanupDuplicateViews() async {
    try {
      final result = await ViewBackendService.cleanupDuplicatePrivateViews();
      result.fold(
        (cleanedCount) {
          if (cleanedCount > 0) {
            showSnackBarMessage(
              context,
              '已清理 $cleanedCount 个重复项目',
              showCancel: false,
            );
            // 触发重新同步
            _syncMenuItemsFromBloc();
          } else {
            showSnackBarMessage(
              context,
              '没有发现重复项目',
              showCancel: false,
            );
          }
        },
        (error) {
          showSnackBarMessage(
            context,
            '清理失败: ${error.msg}',
            showCancel: false,
          );
        },
      );
    } catch (e) {
      showSnackBarMessage(
        context,
        '清理失败: $e',
        showCancel: false,
      );
    }
  }
}

