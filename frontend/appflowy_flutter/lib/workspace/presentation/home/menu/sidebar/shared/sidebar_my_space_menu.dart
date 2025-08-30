import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

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

/// 添加根级项目对话框
class _AddRootItemDialog extends StatefulWidget {
  final Function(MySpaceItemType type, String name) onAddItem;

  const _AddRootItemDialog({required this.onAddItem});

  @override
  State<_AddRootItemDialog> createState() => _AddRootItemDialogState();
}

class _AddRootItemDialogState extends State<_AddRootItemDialog> {
  MySpaceItemType _selectedType = MySpaceItemType.folder;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新项目'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 项目类型选择
          Row(
            children: [
              const Text('类型：'),
              const HSpace(16.0),
              ...MySpaceItemType.values.map((type) => 
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<MySpaceItemType>(
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    Text(_getTypeDisplayName(type)),
                    const HSpace(8.0),
                  ],
                )
              ).toList(),
            ],
          ),
          const VSpace(16.0),
          // 项目名称输入
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '项目名称',
              hintText: '请输入项目名称',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty 
              ? null 
              : () {
                  widget.onAddItem(_selectedType, _nameController.text.trim());
                  Navigator.of(context).pop();
                },
          child: const Text('添加'),
        ),
      ],
    );
  }

  /// 获取类型显示名称
  String _getTypeDisplayName(MySpaceItemType type) {
    switch (type) {
      case MySpaceItemType.folder:
        return '📁 文件夹';
      case MySpaceItemType.notebook:
        return '📚 笔记本';
      case MySpaceItemType.note:
        return '📝 笔记';
    }
  }
}

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
  // 是否全部展开的状态
  bool _isAllExpanded = false;
  // 我的空间主菜单是否展开的状态
  bool _isMainMenuExpanded = true;
  
  // 示例数据 - 在实际应用中这些数据应该从后端获取
  final List<MySpaceMenuItem> _menuItems = [
    MySpaceMenuItem(
      id: '1',
      name: '小马笔记教程',
      icon: '👋',
      type: MySpaceItemType.notebook,
      children: [
        MySpaceMenuItem(
          id: '1-1',
          name: '基础教程',
          icon: '📖',
          type: MySpaceItemType.note,
        ),
        MySpaceMenuItem(
          id: '1-2',
          name: '高级功能',
          icon: '📚',
          type: MySpaceItemType.note,
        ),
      ],
    ),
    MySpaceMenuItem(
      id: '2',
      name: '文件夹',
      icon: '📁',
      type: MySpaceItemType.folder,
      children: [
        MySpaceMenuItem(
          id: '2-1',
          name: '子文件夹',
          icon: '📁',
          type: MySpaceItemType.folder,
          children: [
            MySpaceMenuItem(
              id: '2-1-1',
              name: '文件夹下的笔记本',
              icon: '📚',
              type: MySpaceItemType.notebook,
              children: [
                MySpaceMenuItem(
                  id: '2-1-1-1',
                  name: '文件夹下的笔记',
                  icon: '📝',
                  type: MySpaceItemType.note,
                ),
              ],
            ),
          ],
        ),
        MySpaceMenuItem(
          id: '2-2',
          name: '文件夹下的笔记本',
          icon: '📚',
          type: MySpaceItemType.notebook,
          children: [
            MySpaceMenuItem(
              id: '2-2-1',
              name: '文件夹下的笔记',
              icon: '📝',
              type: MySpaceItemType.note,
            ),
          ],
        ),
      ],
    ),
    MySpaceMenuItem(
      id: '3',
      name: '每日读书笔记',
      icon: '😇',
      type: MySpaceItemType.notebook,
      children: [
        MySpaceMenuItem(
          id: '3-1',
          name: '读书笔记1',
          icon: '📖',
          type: MySpaceItemType.note,
        ),
        MySpaceMenuItem(
          id: '3-2',
          name: '读书笔记2',
          icon: '📖',
          type: MySpaceItemType.note,
        ),
      ],
    ),
    MySpaceMenuItem(
      id: '4',
      name: 'OP考研笔记本',
      icon: '🙉',
      type: MySpaceItemType.notebook,
      children: [
        MySpaceMenuItem(
          id: '4-1',
          name: '数学笔记',
          icon: '📚',
          type: MySpaceItemType.note,
        ),
        MySpaceMenuItem(
          id: '4-2',
          name: '英语笔记',
          icon: '📚',
          type: MySpaceItemType.note,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 我的空间标题
        _buildHeader(),
        // 菜单项列表（根据主菜单展开状态显示/隐藏）
        if (_isMainMenuExpanded) ...[
          const VSpace(8.0),
          ..._buildMenuItems(_menuItems, 0),
        ],
      ],
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
          // 添加子项目按钮
          GestureDetector(
            onTap: () => _showAddRootItemDialog(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
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
    final canHaveChildren = item.type == MySpaceItemType.folder || 
                           item.type == MySpaceItemType.notebook;
    
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
    final theme = AppFlowyTheme.of(context);
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
                // 操作按钮
                if (isFolder || isNotebook) ...[
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _onAddItem(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: itemColor.withOpacity(0.6),
                  ),
                ],
                // 重命名按钮（所有项目都可以重命名）
                if (level >= 0) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => _onRenameItem(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: itemColor.withOpacity(0.6),
                  ),
                ],
                // 删除按钮（所有项目都可以删除）
                if (level >= 0) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => _onDeleteItem(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: itemColor.withOpacity(0.6),
                  ),
                ],
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
    } else {
      // 处理笔记点击
      debugPrint('点击了笔记: ${item.name}');
      // TODO: 实现笔记打开逻辑
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

  /// 添加新项目
  void _onAddItem(MySpaceMenuItem parentItem) {
    if (parentItem.type == MySpaceItemType.folder) {
      // 文件夹可以添加：子文件夹、笔记本、笔记
      _showAddItemDialog(parentItem, [
        MySpaceItemType.folder,
        MySpaceItemType.notebook,
        MySpaceItemType.note,
      ]);
    } else if (parentItem.type == MySpaceItemType.notebook) {
      // 笔记本只能添加笔记
      _showAddItemDialog(parentItem, [MySpaceItemType.note]);
    }
  }

  /// 显示添加项目对话框
  void _showAddItemDialog(MySpaceMenuItem parentItem, List<MySpaceItemType> allowedTypes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加${_getTypeName(parentItem.type)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: allowedTypes.map((type) => ListTile(
            leading: Icon(_getTypeIcon(type)),
            title: Text('添加${_getTypeName(type)}'),
            onTap: () {
              Navigator.of(context).pop();
              _addNewItem(parentItem, type);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 添加新项目
  void _addNewItem(MySpaceMenuItem parentItem, MySpaceItemType type) {
    final newItem = MySpaceMenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '新建${_getTypeName(type)}',
      icon: _getTypeEmoji(type),
      type: type,
    );

    setState(() {
      _addItemRecursive(_menuItems, parentItem.id, newItem);
    });
  }

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

  /// 获取类型图标
  IconData _getTypeIcon(MySpaceItemType type) {
    switch (type) {
      case MySpaceItemType.folder:
        return Icons.folder;
      case MySpaceItemType.notebook:
        return Icons.book;
      case MySpaceItemType.note:
        return Icons.note;
    }
  }

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

  /// 展开所有项目
  void _expandAll() {
    _isAllExpanded = true;
    _expandAllRecursive(_menuItems);
  }

  /// 收起所有项目
  void _collapseAll() {
    _isAllExpanded = false;
    _collapseAllRecursive(_menuItems);
  }

  /// 递归展开所有项目
  void _expandAllRecursive(List<MySpaceMenuItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].children.isNotEmpty) {
        items[i] = items[i].copyWith(isExpanded: true);
        _expandAllRecursive(items[i].children);
      }
    }
  }

  /// 递归收起所有项目
  void _collapseAllRecursive(List<MySpaceMenuItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].children.isNotEmpty) {
        items[i] = items[i].copyWith(isExpanded: false);
        _collapseAllRecursive(items[i].children);
      }
    }
  }

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
  void _renameItem(MySpaceMenuItem item, String newName) {
    setState(() {
      _renameItemRecursive(_menuItems, item.id, newName);
    });
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
  void _deleteItem(MySpaceMenuItem item) {
    setState(() {
      _deleteItemRecursive(_menuItems, item.id);
    });
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

  /// 显示添加根级项目对话框
  void _showAddRootItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddRootItemDialog(
        onAddItem: (type, name) {
          _addRootItem(type, name);
        },
      ),
    );
  }

  /// 添加根级项目
  void _addRootItem(MySpaceItemType type, String name) {
    final newItem = MySpaceMenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: _getTypeEmoji(type),
      type: type,
      children: [],
      isExpanded: false,
    );

    setState(() {
      _menuItems.add(newItem);
    });
  }
}
