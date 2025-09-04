import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_content_item.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';

class InboxContentList extends StatelessWidget {
  final String selectedFilter;

  const InboxContentList({
    super.key,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    // 模拟数据
    final items = _getMockItems();
    final filteredItems = _filterItems(items);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: filteredItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 17),
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return InboxContentItem(
            item: item,
            onTap: () => _handleItemTap(context, item),
          );
        },
      ),
    );
  }

  List<InboxItem> _getMockItems() {
    return [
      InboxItem(
        id: '1',
        title: '标题名称',
        description: '风控所有点滴生活记录，请珍惜小小的\n幸福，大大的爱',
        date: '2025年6月25日 12:22',
        hasImage: true,
        imageUrl: 'https://via.placeholder.com/115x75',
        isRead: false,
      ),
      InboxItem(
        id: '2',
        title: '标题名称',
        description: '风控所有点滴生活记录，请珍惜小小的\n幸福，大大的爱',
        date: '2025年6月25日 12:22',
        hasImage: false,
        isRead: true,
      ),
      InboxItem(
        id: '3',
        title: '标题名称',
        description: '',
        date: '2025年6月25日 12:22',
        hasImage: true,
        imageUrl: 'https://via.placeholder.com/115x76',
        isRead: false,
      ),
    ];
  }

  List<InboxItem> _filterItems(List<InboxItem> items) {
    switch (selectedFilter) {
      case '未读':
        return items.where((item) => !item.isRead).toList();
      case '剪藏':
        // TODO: 实现剪藏筛选逻辑
        return items.where((item) => item.isClipped).toList();
      case '全部':
      default:
        return items;
    }
  }

  void _handleItemTap(BuildContext context, InboxItem item) {
    // TODO: 实现点击跳转到详情页面
    debugPrint('点击了收件箱项目: ${item.title}');
  }
}
