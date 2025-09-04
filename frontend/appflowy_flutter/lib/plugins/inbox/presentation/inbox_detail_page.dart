import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';

class InboxDetailPage extends StatefulWidget {
  final InboxItem item;

  const InboxDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<InboxDetailPage> createState() => _InboxDetailPageState();
}

class _InboxDetailPageState extends State<InboxDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '收件箱详情',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.item.isStarred ? Icons.star : Icons.star_border,
              color: widget.item.isStarred ? Colors.amber : Colors.grey,
            ),
            onPressed: _toggleStar,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              widget.item.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 状态标签
            Row(
              children: [
                if (!widget.item.isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '未读',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                if (widget.item.isClipped) ...[
                  if (!widget.item.isRead) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '剪藏',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                Text(
                  widget.item.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 图片（如果有）
            if (widget.item.hasImage && widget.item.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.item.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // 描述
            if (widget.item.description.isNotEmpty) ...[
              const Text(
                '描述',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // 内容区域
            const Text(
              '内容',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text(
                '这里将显示收件箱项目的详细内容。\n\n当前显示的是占位文本，实际应用中会从数据库的content字段读取真实内容。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleStar() {
    // TODO: 实现收藏/取消收藏功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.item.isStarred ? '已取消收藏' : '已收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                widget.item.isRead ? Icons.mark_as_unread : Icons.mark_email_read,
              ),
              title: Text(widget.item.isRead ? '标记为未读' : '标记为已读'),
              onTap: () {
                Navigator.pop(context);
                _toggleReadStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                _shareItem();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteItem();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReadStatus() {
    // TODO: 实现标记已读/未读功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.item.isRead ? '已标记为未读' : '已标记为已读'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareItem() {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这个收件箱项目吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 返回到收件箱列表
              // TODO: 实现删除功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('删除功能开发中...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
