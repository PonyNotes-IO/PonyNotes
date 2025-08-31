import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// 添加项目类型
enum AddItemType {
  folder,      // 文件夹
  notebook,    // 笔记本
  note,        // 笔记
}

/// 添加项目下拉菜单
class AddItemDropdown extends StatefulWidget {
  const AddItemDropdown({
    super.key,
    required this.onItemSelected,
    this.allowedTypes = const [AddItemType.folder, AddItemType.notebook, AddItemType.note],
    this.buttonSize = 16.0,
  });

  final Function(AddItemType type) onItemSelected;
  final List<AddItemType> allowedTypes;
  final double buttonSize;

  @override
  State<AddItemDropdown> createState() => _AddItemDropdownState();
}

class _AddItemDropdownState extends State<AddItemDropdown> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    // 确保在dispose时移除overlay
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isOpen 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.add,
          size: widget.buttonSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (!mounted) return;
    
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted) return;
    
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    if (!mounted) return;
    
    setState(() {
      _isOpen = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.allowedTypes.map((type) => _buildDropdownItem(type)).toList(),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  Widget _buildDropdownItem(AddItemType type) {
    return InkWell(
      onTap: () {
        widget.onItemSelected(type);
        _removeOverlay();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              _getTypeEmoji(type),
              style: const TextStyle(fontSize: 16),
            ),
            const HSpace(8),
            Text(
              _getTypeName(type),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  /// 获取类型名称
  String _getTypeName(AddItemType type) {
    switch (type) {
      case AddItemType.folder:
        return '文件夹';
      case AddItemType.notebook:
        return '笔记本';
      case AddItemType.note:
        return '笔记';
    }
  }

  /// 获取类型emoji
  String _getTypeEmoji(AddItemType type) {
    switch (type) {
      case AddItemType.folder:
        return '📁';
      case AddItemType.notebook:
        return '📚';
      case AddItemType.note:
        return '📝';
    }
  }
}

/// 添加项目按钮（带悬停显示）
class AddItemButton extends StatefulWidget {
  const AddItemButton({
    super.key,
    required this.onItemSelected,
    this.allowedTypes = const [AddItemType.folder, AddItemType.notebook, AddItemType.note],
    this.showOnHover = true,
    this.buttonSize = 16.0,
  });

  final Function(AddItemType type) onItemSelected;
  final List<AddItemType> allowedTypes;
  final bool showOnHover;
  final double buttonSize;

  @override
  State<AddItemButton> createState() => _AddItemButtonState();
}

class _AddItemButtonState extends State<AddItemButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.showOnHover) {
      return MouseRegion(
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _isHovered = false);
        },
        child: AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AddItemDropdown(
            onItemSelected: widget.onItemSelected,
            allowedTypes: widget.allowedTypes,
            buttonSize: widget.buttonSize,
          ),
        ),
      );
    } else {
      return AddItemDropdown(
        onItemSelected: widget.onItemSelected,
        allowedTypes: widget.allowedTypes,
        buttonSize: widget.buttonSize,
      );
    }
  }
}
