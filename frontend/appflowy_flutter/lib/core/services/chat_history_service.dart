import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? error;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'error': error,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    error: json['error'],
  );

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
    );
  }
}

/// 聊天会话模型
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    messages: (json['messages'] as List)
        .map((m) => ChatMessage.fromJson(m))
        .toList(),
  );

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

/// 聊天历史管理服务
class ChatHistoryService {
  static ChatHistoryService? _instance;
  static ChatHistoryService get instance => _instance ??= ChatHistoryService._();
  ChatHistoryService._();

  static const String _historyFileName = 'chat_history.json';
  File? _historyFile;
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;

  /// 初始化服务
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _historyFile = File('${directory.path}/$_historyFileName');
      await _loadHistory();
    } catch (e) {
      debugPrint('❌ 初始化聊天历史服务失败: $e');
    }
  }

  /// 加载历史记录
  Future<void> _loadHistory() async {
    try {
      if (_historyFile?.existsSync() == true) {
        final content = await _historyFile!.readAsString();
        final jsonData = jsonDecode(content) as Map<String, dynamic>;
        final sessionsJson = jsonData['sessions'] as List? ?? [];
        
        _sessions = sessionsJson
            .map((s) => ChatSession.fromJson(s))
            .toList();
        
        // 按更新时间排序，最新的在前
        _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        debugPrint('✅ 成功加载 ${_sessions.length} 个聊天会话');
      }
    } catch (e) {
      debugPrint('❌ 加载聊天历史失败: $e');
    }
  }

  /// 保存历史记录
  Future<void> _saveHistory() async {
    try {
      if (_historyFile == null) return;
      
      final jsonData = {
        'version': '1.0',
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'sessions': _sessions.map((s) => s.toJson()).toList(),
      };
      
      await _historyFile!.writeAsString(jsonEncode(jsonData));
      debugPrint('💾 聊天历史已保存');
    } catch (e) {
      debugPrint('❌ 保存聊天历史失败: $e');
    }
  }

  /// 创建新会话
  ChatSession createNewSession({String? title}) {
    final now = DateTime.now();
    final session = ChatSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      title: title ?? '新对话',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    
    _sessions.insert(0, session);
    _currentSession = session;
    _saveHistory();
    
    debugPrint('📝 创建新会话: ${session.title}');
    return session;
  }

  /// 获取当前会话
  ChatSession getCurrentSession() {
    _currentSession ??= createNewSession();
    return _currentSession!;
  }

  /// 设置当前会话
  void setCurrentSession(ChatSession session) {
    _currentSession = session;
    debugPrint('🔄 切换到会话: ${session.title}');
  }

  /// 添加消息到当前会话
  Future<void> addMessage(ChatMessage message) async {
    final session = getCurrentSession();
    final updatedMessages = List<ChatMessage>.from(session.messages)..add(message);
    
    // 如果是第一条用户消息，用它来生成会话标题
    String title = session.title;
    if (session.messages.isEmpty && message.isUser) {
      title = _generateSessionTitle(message.content);
    }
    
    final updatedSession = session.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
      title: title,
    );
    
    // 更新会话列表
    final sessionIndex = _sessions.indexWhere((s) => s.id == session.id);
    if (sessionIndex >= 0) {
      _sessions[sessionIndex] = updatedSession;
      // 将更新的会话移到最前面
      if (sessionIndex > 0) {
        _sessions.removeAt(sessionIndex);
        _sessions.insert(0, updatedSession);
      }
    }
    
    _currentSession = updatedSession;
    await _saveHistory();
  }

  /// 生成会话标题
  String _generateSessionTitle(String firstMessage) {
    // 取前20个字符作为标题
    String title = firstMessage.length > 20 
        ? '${firstMessage.substring(0, 20)}...' 
        : firstMessage;
    
    // 移除换行符
    title = title.replaceAll('\n', ' ').trim();
    
    return title.isEmpty ? '新对话' : title;
  }

  /// 更新消息内容（用于流式更新）
  Future<void> updateMessage(String messageId, String content, {String? error}) async {
    final session = getCurrentSession();
    final messageIndex = session.messages.indexWhere((m) => m.id == messageId);
    
    if (messageIndex >= 0) {
      final updatedMessage = session.messages[messageIndex].copyWith(
        content: content,
        error: error,
      );
      
      final updatedMessages = List<ChatMessage>.from(session.messages);
      updatedMessages[messageIndex] = updatedMessage;
      
      final updatedSession = session.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
      
      final sessionIndex = _sessions.indexWhere((s) => s.id == session.id);
      if (sessionIndex >= 0) {
        _sessions[sessionIndex] = updatedSession;
      }
      
      _currentSession = updatedSession;
      await _saveHistory();
    }
  }

  /// 获取所有会话
  List<ChatSession> getAllSessions() => List.unmodifiable(_sessions);

  /// 删除会话
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    
    if (_currentSession?.id == sessionId) {
      _currentSession = _sessions.isNotEmpty ? _sessions.first : null;
    }
    
    await _saveHistory();
    debugPrint('🗑️ 删除会话: $sessionId');
  }

  /// 清空所有历史
  Future<void> clearAllHistory() async {
    _sessions.clear();
    _currentSession = null;
    await _saveHistory();
    debugPrint('🧹 清空所有聊天历史');
  }

  /// 导出聊天历史
  Future<String> exportHistory() async {
    try {
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'sessions': _sessions.map((s) => s.toJson()).toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('❌ 导出聊天历史失败: $e');
      rethrow;
    }
  }

  /// 导入聊天历史
  Future<void> importHistory(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final sessionsJson = data['sessions'] as List? ?? [];
      
      final importedSessions = sessionsJson
          .map((s) => ChatSession.fromJson(s))
          .toList();
      
      _sessions.addAll(importedSessions);
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      await _saveHistory();
      debugPrint('📥 成功导入 ${importedSessions.length} 个聊天会话');
    } catch (e) {
      debugPrint('❌ 导入聊天历史失败: $e');
      rethrow;
    }
  }
}
