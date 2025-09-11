import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'standalone_chat_bloc.dart';

/// 独立AI聊天持久化服务
/// 负责与Rust后端进行数据交互，保存和加载聊天记录
class StandaloneChatPersistence {
  static StandaloneChatPersistence? _instance;
  static StandaloneChatPersistence get instance => 
      _instance ??= StandaloneChatPersistence._();
  StandaloneChatPersistence._();

  // 独立聊天的固定ID，用于标识这是独立AI聊天
  static const String standaloneChatId = 'standalone_ai_chat';
  static const String standaloneWorkspaceId = 'standalone_workspace';

  /// 保存消息到后端数据库
  Future<void> saveMessage(ChatMessage message) async {
    try {
      // 创建消息数据结构 - 为将来与Rust后端集成保留
      // final messageData = {
      //   'id': message.id,
      //   'content': message.content,
      //   'isUser': message.isUser,
      //   'timestamp': message.timestamp.millisecondsSinceEpoch,
      //   'aiProvider': message.aiProvider?.id,
      // };

      // 调用Rust后端保存消息
      await _saveMessageToBackend(message);
      
      debugPrint('✅ 消息已保存: ${message.content.length > 50 ? message.content.substring(0, 50) + '...' : message.content}');
    } catch (e) {
      debugPrint('❌ 保存消息失败: $e');
      // 不抛出异常，避免影响用户体验
    }
  }

  /// 从后端数据库加载消息
  Future<List<ChatMessage>> loadMessages() async {
    try {
      debugPrint('🔄 开始加载历史消息...');
      
      // 从Rust后端加载消息
      final messages = await _loadMessagesFromBackend();
      
      debugPrint('✅ 加载了 ${messages.length} 条历史消息');
      return messages;
    } catch (e) {
      debugPrint('❌ 加载历史消息失败: $e');
      return []; // 返回空列表，不影响用户体验
    }
  }

  /// 清空所有消息
  Future<void> clearMessages() async {
    try {
      await _clearMessagesFromBackend();
      debugPrint('✅ 已清空所有聊天记录');
    } catch (e) {
      debugPrint('❌ 清空聊天记录失败: $e');
      rethrow; // 清空失败需要让用户知道
    }
  }

  /// 调用Rust后端保存消息
  Future<void> _saveMessageToBackend(ChatMessage message) async {
    try {
      // 构造消息内容 - 为将来与Rust后端集成保留
      // final messageContent = jsonEncode({
      //   'id': message.id,
      //   'content': message.content,
      //   'isUser': message.isUser,
      //   'timestamp': message.timestamp.millisecondsSinceEpoch,
      //   'aiProvider': message.aiProvider?.id,
      // });

      // 创建聊天消息PB对象 - 为将来与Rust后端集成保留
      // final chatMessagePB = ChatMessagePB()
      //   ..messageId = Int64.parseInt(message.id)
      //   ..content = messageContent
      //   ..authorType = Int64(message.isUser ? 1 : 2)
      //   ..createdAt = Int64(message.timestamp.millisecondsSinceEpoch);

      // 如果聊天不存在，先创建聊天
      await _ensureChatExists();

      // 保存消息 - 这里使用简化的方式，直接存储JSON字符串
      // 真正的实现需要与Rust后端的具体API对接
      debugPrint('📝 尝试保存消息到后端: ${message.content.length > 20 ? message.content.substring(0, 20) + '...' : message.content}');
      
      // TODO: 这里需要根据实际的Rust后端API来实现
      // 现在先用调试信息模拟保存过程
      await Future.delayed(const Duration(milliseconds: 10));
      
    } catch (e) {
      debugPrint('后端保存失败: $e');
      rethrow;
    }
  }

  /// 从Rust后端加载消息
  Future<List<ChatMessage>> _loadMessagesFromBackend() async {
    try {
      // TODO: 这里需要根据实际的Rust后端API来实现
      // 现在先返回空列表，模拟加载过程
      await Future.delayed(const Duration(milliseconds: 50));
      
      debugPrint('🔍 尝试从后端加载消息...');
      
      // 这里应该调用类似的API:
      // final result = await AIEventGetChatMessages(GetChatMessagesPB()
      //   ..chatId = standaloneChatId).send();
      
      return <ChatMessage>[];
    } catch (e) {
      debugPrint('后端加载失败: $e');
      return <ChatMessage>[];
    }
  }

  /// 从Rust后端清空消息
  Future<void> _clearMessagesFromBackend() async {
    try {
      // TODO: 这里需要根据实际的Rust后端API来实现
      await Future.delayed(const Duration(milliseconds: 30));
      
      debugPrint('🗑️ 尝试清空后端消息...');
      
      // 这里应该调用类似的API:
      // await AIEventClearChatMessages(ClearChatMessagesPB()
      //   ..chatId = standaloneChatId).send();
      
    } catch (e) {
      debugPrint('后端清空失败: $e');
      rethrow;
    }
  }

  /// 确保聊天存在
  Future<void> _ensureChatExists() async {
    try {
      // TODO: 检查聊天是否存在，如果不存在则创建
      // 这里应该调用类似的API:
      // final result = await AIEventCreateChat(CreateChatPB()
      //   ..chatId = standaloneChatId
      //   ..name = '独立AI聊天').send();
      
      debugPrint('🔍 确保独立聊天存在...');
      await Future.delayed(const Duration(milliseconds: 5));
    } catch (e) {
      debugPrint('创建聊天失败: $e');
      // 不抛出异常，继续尝试保存消息
    }
  }

  /// 获取聊天统计信息
  Future<Map<String, dynamic>> getChatStats() async {
    try {
      final messages = await loadMessages();
      final userMessages = messages.where((m) => m.isUser).length;
      final aiMessages = messages.where((m) => !m.isUser).length;
      
      return {
        'totalMessages': messages.length,
        'userMessages': userMessages,
        'aiMessages': aiMessages,
        'lastMessageTime': messages.isNotEmpty 
            ? messages.last.timestamp.toIso8601String()
            : null,
      };
    } catch (e) {
      debugPrint('获取聊天统计失败: $e');
      return {
        'totalMessages': 0,
        'userMessages': 0,
        'aiMessages': 0,
        'lastMessageTime': null,
      };
    }
  }

  /// 搜索消息内容
  Future<List<ChatMessage>> searchMessages(String query) async {
    try {
      final allMessages = await loadMessages();
      return allMessages.where((message) {
        return message.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('搜索消息失败: $e');
      return [];
    }
  }

  /// 导出聊天记录
  Future<String> exportChat() async {
    try {
      final messages = await loadMessages();
      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'chatId': standaloneChatId,
        'totalMessages': messages.length,
        'messages': messages.map((m) => {
          'id': m.id,
          'content': m.content,
          'isUser': m.isUser,
          'timestamp': m.timestamp.toIso8601String(),
          'aiProvider': m.aiProvider?.id,
        }).toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('导出聊天记录失败: $e');
      rethrow;
    }
  }
}
