import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_content_item.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';
import 'package:appflowy/plugins/inbox/presentation/inbox_detail_page.dart';
import 'package:sqflite/sqflite.dart';

class InboxContentList extends StatefulWidget {
  final String selectedFilter;
  final Function(InboxItem)? onItemSelected;
  final InboxItem? selectedItem;

  const InboxContentList({
    super.key,
    required this.selectedFilter,
    this.onItemSelected,
    this.selectedItem,
  });

  @override
  State<InboxContentList> createState() => _InboxContentListState();
}

class _InboxContentListState extends State<InboxContentList> {
  List<InboxItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInboxItems();
  }

  @override
  void didUpdateWidget(InboxContentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      _loadInboxItems();
    }
  }

  Future<void> _loadInboxItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _getInboxItemsFromDatabase();
      final filteredItems = _filterItems(items);
      setState(() {
        _items = filteredItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading inbox items: $e');
      // 如果数据库查询失败，使用模拟数据
      final mockItems = _getMockItems();
      final filteredItems = _filterItems(mockItems);
      setState(() {
        _items = filteredItems;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 17),
        itemBuilder: (context, index) {
          final item = _items[index];
          final isSelected = widget.selectedItem?.id == item.id;
          return InboxContentItem(
            item: item,
            isSelected: isSelected,
            onTap: () => _handleItemTap(context, item),
          );
        },
      ),
    );
  }

  Future<List<InboxItem>> _getInboxItemsFromDatabase() async {
    try {
      // 数据库路径
      const dbPath = '/Users/kuncao/Library/Application Support/com.appflowy.appflowy.flutter/ponynotes_data_dev_api.xiaomabiji.com/1756905910/flowy-database.db';
      
      final database = await openDatabase(dbPath, readOnly: true);
      
      final List<Map<String, dynamic>> maps = await database.query(
        'inbox_table',
        orderBy: 'created_at DESC',
      );
      
      await database.close();
      
      return maps.map((map) {
        // 将时间戳转换为可读格式
        final createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at'] * 1000);
        final dateStr = '${createdAt.year}年${createdAt.month}月${createdAt.day}日 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        
        return InboxItem(
          id: map['id'] ?? '',
          title: map['title'] ?? '',
          description: map['description'] ?? '',
          date: dateStr,
          hasImage: map['image_url'] != null && map['image_url'].toString().isNotEmpty,
          imageUrl: map['image_url'],
          isRead: (map['is_read'] ?? 0) == 1,
          isClipped: (map['is_clipped'] ?? 0) == 1,
          isStarred: (map['is_starred'] ?? 0) == 1,
        );
      }).toList();
    } catch (e) {
      print('Database query error: $e');
      throw e;
    }
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
        isStarred: false,
      ),
      InboxItem(
        id: '2',
        title: '标题名称',
        description: '风控所有点滴生活记录，请珍惜小小的\n幸福，大大的爱',
        date: '2025年6月25日 12:22',
        hasImage: false,
        isRead: true,
        isClipped: true,
        isStarred: true,
      ),
      InboxItem(
        id: '3',
        title: '标题名称',
        description: '',
        date: '2025年6月25日 12:22',
        hasImage: true,
        imageUrl: 'https://via.placeholder.com/115x76',
        isRead: false,
        isStarred: true,
      ),
    ];
  }

  List<InboxItem> _filterItems(List<InboxItem> items) {
    switch (widget.selectedFilter) {
      case '未读':
        return items.where((item) => !item.isRead).toList();
      case '剪藏':
        return items.where((item) => item.isClipped).toList();
      case '全部':
      default:
        return items;
    }
  }

  void _handleItemTap(BuildContext context, InboxItem item) {
    // 如果有回调函数，使用回调（新的2栏布局模式）
    if (widget.onItemSelected != null) {
      widget.onItemSelected!(item);
    } else {
      // 否则使用原来的导航方式（向后兼容）
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InboxDetailPage(item: item),
        ),
      );
    }
  }
}
