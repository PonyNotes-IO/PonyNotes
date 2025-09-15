import 'package:flutter/material.dart';
import 'package:appflowy/util/theme_extension.dart';

class InboxFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const InboxFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: Row(
        children: [
          _buildFilterTab(context, '全部', hasNotification: true),
          const SizedBox(width: 10),
          _buildFilterTab(context, '未读'),
          const SizedBox(width: 10),
          _buildFilterTab(context, '已收藏'),
          const SizedBox(width: 10),
          _buildFilterTab(context, '重要'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(BuildContext context, String label, {bool hasNotification = false}) {
    final isSelected = selectedFilter == label;
    final isLightMode = Theme.of(context).isLightMode;
    
    final backgroundColor = isSelected 
        ? (isLightMode ? const Color(0xFFEFEFEF) : const Color(0xFF2C2C2C))
        : (isLightMode ? Colors.white : const Color(0xFF1E1E1E));
    
    final borderColor = isLightMode 
        ? const Color(0xFFE9E9E9) 
        : const Color(0xFF3C3C3C);
    
    final textColor = isLightMode 
        ? Colors.black87 
        : Colors.white70;
    
    return GestureDetector(
      onTap: () => onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: textColor,
              ),
            ),
            if (hasNotification)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
