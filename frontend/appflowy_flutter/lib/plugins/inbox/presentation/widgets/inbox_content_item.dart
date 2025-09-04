import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';

class InboxContentItem extends StatelessWidget {
  final InboxItem item;
  final VoidCallback onTap;
  final bool isSelected;

  const InboxContentItem({
    super.key,
    required this.item,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 75,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: const Color(0xFF4A90E2), width: 1)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧内容区域
            Expanded(
              child: _buildContentArea(),
            ),
            
            // 右侧图片区域
            if (item.hasImage && item.imageUrl != null)
              _buildImageArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        
        // 描述内容（如果有）
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              item.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        
        // 日期
        const Spacer(),
        Text(
          item.date,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF636363),
          ),
        ),
      ],
    );
  }

  Widget _buildImageArea() {
    return Container(
      margin: const EdgeInsets.only(left: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 115,
          height: 75,
          color: const Color(0xFFF0F0F0),
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  width: 115,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildPlaceholderImage();
                  },
                )
              : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 115,
      height: 75,
      color: const Color(0xFFF0F0F0),
      child: const Icon(
        Icons.image,
        color: Color(0xFFCCCCCC),
        size: 32,
      ),
    );
  }
}
