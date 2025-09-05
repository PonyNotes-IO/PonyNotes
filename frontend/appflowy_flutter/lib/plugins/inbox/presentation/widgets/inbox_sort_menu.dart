import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/domain/models/sort_option.dart';

class InboxSortMenu extends StatelessWidget {
  final SortOption currentSort;
  final Function(SortOption) onSortChanged;
  final VoidCallback onClose;

  const InboxSortMenu({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 菜单标题
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '排序方式',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // 排序选项
          ...SortOption.values.map((option) => _buildSortOption(option)),
        ],
      ),
    ),
    );
  }

  Widget _buildSortOption(SortOption option) {
    final isSelected = option == currentSort;
    
    return GestureDetector(
      onTap: () {
        onSortChanged(option);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(
              option.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF333333),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
          ],
        ),
      ),
    );
  }
}
