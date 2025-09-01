import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
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

  const MySpaceMenuItem({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    this.children = const [],
    this.isExpanded = false,
  });

  MySpaceMenuItem copyWith({
    String? id,
    String? name,
    String? icon,
    MySpaceItemType? type,
    List<MySpaceMenuItem>? children,
    bool? isExpanded,
  }) {
    return MySpaceMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
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
    if (item.type == MySpaceItemType.folder || item.type == MySpaceItemType.notebook) {
      // 添加文件夹
      if (item.type == MySpaceItemType.folder) {
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
      
      // 添加笔记本
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
      
      // 添加笔记
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

  /// 递归添加项目
  bool _addItemRecursive(List<MySpaceMenuItem> items, String parentId, MySpaceMenuItem newItem) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == parentId) {
        items[i] = items[i].copyWith(
          children: [...items[i].children, newItem],
          isExpanded: true, // 自动展开父项目
        );
        return true;
      }
      if (_addItemRecursive(items[i].children, parentId, newItem)) {
        return true;
      }
    }
    return false;
  }

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
      // 调用后端API进行真实重命名
      if (item.type == MySpaceItemType.note) {
        // 对于笔记类型，调用真实的重命名API
        final result = await ViewBackendService.updateView(
          viewId: item.id,
          name: newName,
        );
        
        result.fold(
          (success) {
            // 重命名成功，显示提示
            showMessageToast('已重命名为: $newName', context: context);
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
        // 对于文件夹和笔记本类型，目前只做UI重命名
        // TODO: 当后端支持文件夹和笔记本类型时，这里也需要调用相应的重命名API
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

      // 2. 调用后端API真实删除
      if (item.type == MySpaceItemType.note) {
        // 对于笔记类型，调用真实的删除API
        final result = await ViewBackendService.deleteView(viewId: item.id);
        
        result.fold(
          (success) {
            // 删除成功，显示提示
            showMessageToast('已删除笔记: ${item.name}', context: context);
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
        // 对于文件夹和笔记本类型，目前只做UI删除
        // TODO: 当后端支持文件夹和笔记本类型时，这里也需要调用相应的删除API
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
    // 生成临时ID用于UI
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newItem = MySpaceMenuItem(
      id: tempId,
      name: name,
      icon: _getTypeEmoji(type),
      type: type,
      children: [],
      isExpanded: false,
    );

    // 先更新UI（提供即时反馈）
    setState(() {
      _menuItems.add(newItem);
    });

    // TODO: 当后端支持文件夹和笔记本类型时，在这里调用相应的创建API
    // 目前文件夹和笔记本只在UI层存在，将来可以扩展为真实的后端操作
    showMessageToast('已创建${_getTypeName(type)}: $name', context: context);
  }

  /// 添加根级项目（使用默认名称）
  void _addRootItemWithDefaultName(MySpaceItemType type) {
    final defaultName = '未命名${_getTypeName(type)}';
    
    // 如果是笔记类型，创建真实的文档
    if (type == MySpaceItemType.note) {
      _createRealDocument(defaultName);
    } else {
      // 其他类型保持原有逻辑
      _addRootItem(type, defaultName);
    }
  }

  /// 添加子项目（使用默认名称）
  void _addChildItemWithDefaultName(MySpaceMenuItem parentItem, MySpaceItemType type) {
    final defaultName = '未命名${_getTypeName(type)}';
    
    // 如果是笔记类型，创建真实的文档
    if (type == MySpaceItemType.note) {
      _createRealDocument(defaultName);
    } else {
      // 其他类型保持原有逻辑
      final newItem = MySpaceMenuItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: defaultName,
        icon: _getTypeEmoji(type),
        type: type,
      );

      setState(() {
        _addItemRecursive(_menuItems, parentItem.id, newItem);
      });
    }
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



  /// 创建真实的文档 - 复用"个人的"主菜单的创建逻辑，但放在私有区域
  void _createRealDocument(String name) {
    // 使用与PersonalSectionFolder相同的逻辑创建文档，但文档放在私有区域（"我的空间"对应私有区域）
    context.read<SidebarSectionsBloc>().add(
      SidebarSectionsEvent.createRootViewInSection(
        name: name,
        index: 0,
        viewSection: ViewSectionPB.Private, // 使用私有区域，对应"我的空间"
      ),
    );
  }

  /// 打开已存在的文档 - 复用"个人的"主菜单的打开逻辑
  void _openExistingDocument(MySpaceMenuItem item) {
    // 这里需要根据item.id找到对应的ViewPB并打开
    // 由于当前MySpaceMenuItem只是UI模型，需要映射到实际的ViewPB
    // 暂时先显示提示，后续可以通过ViewBackendService.getView来获取实际文档
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在打开笔记: ${item.name}')),
    );
    
    // TODO: 实现真实的文档打开逻辑
    // 需要将MySpaceMenuItem的id映射到实际的ViewPB.id
    // 然后使用TabsBloc.openPlugin来打开文档
  }

  /// 从SidebarSectionsBloc同步菜单项（智能合并，保持UI状态）
  void _syncMenuItemsFromBloc() {
    if (!mounted) return;
    
    try {
      final sidebarSectionsBloc = context.read<SidebarSectionsBloc>();
      final privateViews = sidebarSectionsBloc.state.section.privateViews;
      
      setState(() {
        _menuItems = _mergeViewsWithLocalState(privateViews, _menuItems);
      });
    } catch (e) {
      // 如果context还未准备好，忽略错误
      // 会在BlocListener中重新尝试
    }
  }

  /// 智能合并后端数据与本地状态，保持UI层的修改
  List<MySpaceMenuItem> _mergeViewsWithLocalState(
    List<ViewPB> backendViews,
    List<MySpaceMenuItem> localItems,
  ) {
    final result = <MySpaceMenuItem>[];
    final validBackendViews = _filterValidViews(backendViews);
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
        result.add(existingLocal.copyWith(
          name: view.name, // 同步名称变化
          // 保持 isExpanded, children 等UI状态不变
        ));
      } else {
        // 如果本地不存在，创建新项目
        result.add(_convertViewToMenuItem(view));
      }
    }

    // 2. 保留本地新增但尚未同步到后端的项目（仅限UI-only项目）
    for (final localItem in localItems) {
      if (!backendViewsMap.containsKey(localItem.id) && 
          _isUIOnlyItem(localItem)) {
        result.add(localItem);
      }
    }

    return result;
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

  /// 将ViewPB列表转换为MySpaceMenuItem列表
  /// 注意：此方法已被_mergeViewsWithLocalState替代，保留用于备份
  @Deprecated('使用_mergeViewsWithLocalState代替，以保持UI状态')
  List<MySpaceMenuItem> _convertViewsToMenuItems(List<ViewPB> views) {
    // 过滤有效的视图，避免重复和无效项
    final validViews = _filterValidViews(views);
    return validViews.map((view) => _convertViewToMenuItem(view)).toList();
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
    // 根据ViewPB的类型判断MySpaceItemType
    MySpaceItemType itemType;
    switch (view.layout) {
      case ViewLayoutPB.Document:
        itemType = MySpaceItemType.note;
        break;
      case ViewLayoutPB.Grid:
      case ViewLayoutPB.Board:
      case ViewLayoutPB.Calendar:
        itemType = MySpaceItemType.notebook;
        break;
      default:
        itemType = MySpaceItemType.folder;
        break;
    }

    return MySpaceMenuItem(
      id: view.id,
      name: view.name,
      type: itemType,
      children: [], // 暂不处理子项目，后续可根据需要扩展
      isExpanded: false,
    );
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
