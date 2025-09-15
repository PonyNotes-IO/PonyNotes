import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';

class InboxService {
  InboxService();

  Future<List<InboxItem>> loadItems() async {
    // 模拟数据加载
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      InboxItem(
        id: '1',
        title: '项目会议纪要',
        description: '今天的项目会议讨论了新功能的开发计划...',
        content: '今天的项目会议讨论了新功能的开发计划，包括用户界面优化、性能提升和新特性开发。团队决定采用敏捷开发模式，每两周进行一次迭代。',
        date: '2小时前',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        isStarred: true,
        isImportant: true,
        source: '会议',
        tags: ['工作', '重要'],
      ),
      InboxItem(
        id: '2',
        title: '用户反馈收集',
        description: '用户对新界面设计的反馈意见汇总...',
        content: '用户对新界面设计的反馈意见汇总，主要集中在导航栏设计、颜色搭配和操作流程的简化上。总体反馈积极，建议继续优化细节。',
        date: '5小时前',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        isStarred: false,
        isImportant: false,
        source: '反馈',
        tags: ['用户体验'],
      ),
      InboxItem(
        id: '3',
        title: '技术文档更新',
        description: '最新的API文档已经更新，请查看相关变更...',
        content: '最新的API文档已经更新，请查看相关变更。主要包括新增的用户认证接口、数据同步机制和错误处理规范。开发团队请及时更新本地文档。',
        date: '1天前',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
        isStarred: true,
        isImportant: false,
        source: '文档',
        tags: ['技术', '文档'],
      ),
    ];
  }

  Future<void> markAsRead(String itemId) async {
    // 模拟标记为已读操作
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> markAllAsRead() async {
    // 模拟标记所有为已读操作
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> toggleStar(String itemId, bool isStarred) async {
    // 模拟切换收藏状态操作
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> toggleImportant(String itemId, bool isImportant) async {
    // 模拟切换重要状态操作
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> deleteItem(String itemId) async {
    // 模拟删除操作
    await Future.delayed(const Duration(milliseconds: 200));
  }
} 