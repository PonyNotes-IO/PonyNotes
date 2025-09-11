import 'dart:async';
import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:appflowy/core/config/ai_config.dart';
import '../services/standalone_ai_service.dart';
import 'standalone_chat_persistence.dart';

part 'standalone_chat_bloc.freezed.dart';

/// 独立AI聊天的事件
@freezed
class StandaloneChatEvent with _$StandaloneChatEvent {
  const factory StandaloneChatEvent.sendMessage({
    required String message,
    AIProvider? provider,
  }) = _SendMessage;

  const factory StandaloneChatEvent.receiveStreamChunk({
    required String chunk,
  }) = _ReceiveStreamChunk;

  const factory StandaloneChatEvent.finishResponse() = _FinishResponse;

  const factory StandaloneChatEvent.errorOccurred({
    required String error,
  }) = _ErrorOccurred;

  const factory StandaloneChatEvent.loadHistory() = _LoadHistory;

  const factory StandaloneChatEvent.clearChat() = _ClearChat;

  const factory StandaloneChatEvent.changeProvider({
    required AIProvider provider,
  }) = _ChangeProvider;

  // 聊天历史相关事件
  const factory StandaloneChatEvent.loadChatHistory() = _LoadChatHistory;

  const factory StandaloneChatEvent.loadChatSession({
    required String sessionId,
  }) = _LoadChatSession;

  const factory StandaloneChatEvent.createNewChatSession() = _CreateNewChatSession;

  const factory StandaloneChatEvent.renameChatSession({
    required String sessionId,
    required String newTitle,
  }) = _RenameChatSession;

  const factory StandaloneChatEvent.deleteChatSessions({
    required List<String> sessionIds,
  }) = _DeleteChatSessions;

  const factory StandaloneChatEvent.clearAllChatHistory() = _ClearAllChatHistory;

  const factory StandaloneChatEvent.exportChatHistory() = _ExportChatHistory;

  // 消息相关事件
  const factory StandaloneChatEvent.retryMessage({
    required String messageId,
  }) = _RetryMessage;

  const factory StandaloneChatEvent.editMessage({
    required String messageId,
    required String newContent,
  }) = _EditMessage;
}

/// 独立AI聊天的状态
@freezed
class StandaloneChatState with _$StandaloneChatState {
  const factory StandaloneChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    @Default(false) bool isStreaming,
    String? error,
    String? currentStreamingMessage,
    AIProvider? selectedProvider,
    @Default(false) bool isHistoryLoaded,
    @Default([]) List<ChatSession> chatSessions,
  }) = _StandaloneChatState;
}

/// 聊天消息模型
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required bool isUser,
    required DateTime timestamp,
    AIProvider? aiProvider,
    AIProvider? provider, // 添加provider别名，与aiProvider相同
    @Default(false) bool isStreaming,
    @Default(false) bool hasError,
  }) = _ChatMessage;
}

/// 聊天会话数据模型
@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String id,
    required String title,
    String? lastMessage,
    required DateTime lastMessageTime,
    required int messageCount,
    AIProvider? provider,
  }) = _ChatSession;
}

/// 独立AI聊天Bloc
class StandaloneChatBloc extends Bloc<StandaloneChatEvent, StandaloneChatState> {
  final StandaloneAiService _aiService = StandaloneAiService.instance;
  final AIConfigService _configService = AIConfigService.instance;
  final StandaloneChatPersistence _persistence = StandaloneChatPersistence.instance;
  
  StreamSubscription<String>? _streamSubscription;
  String _currentMessageId = '';

  StandaloneChatBloc() : super(const StandaloneChatState()) {
    on<StandaloneChatEvent>((event, emit) async {
      event.when(
        sendMessage: (message, provider) => _handleSendMessage(message, provider, emit),
        receiveStreamChunk: (chunk) => _handleReceiveStreamChunk(chunk, emit),
        finishResponse: () => _handleFinishResponse(emit),
        errorOccurred: (error) => _handleErrorOccurred(error, emit),
        loadHistory: () => _handleLoadHistory(emit),
        clearChat: () => _handleClearChat(emit),
        changeProvider: (provider) => _handleChangeProvider(provider, emit),
        loadChatHistory: () => _handleLoadChatHistory(emit),
        loadChatSession: (sessionId) => _handleLoadChatSession(sessionId, emit),
        createNewChatSession: () => _handleCreateNewChatSession(emit),
        renameChatSession: (sessionId, newTitle) => _handleRenameChatSession(sessionId, newTitle, emit),
        deleteChatSessions: (sessionIds) => _handleDeleteChatSessions(sessionIds, emit),
        clearAllChatHistory: () => _handleClearAllChatHistory(emit),
        exportChatHistory: () => _handleExportChatHistory(emit),
        retryMessage: (messageId) => _handleRetryMessage(messageId, emit),
        editMessage: (messageId, newContent) => _handleEditMessage(messageId, newContent, emit),
      );
    });
  }

  @override
  Future<void> close() async {
    debugPrint('🔄 正在关闭StandaloneChatBloc...');
    
    // 取消所有订阅
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    
    debugPrint('✅ StandaloneChatBloc已关闭');
    return super.close();
  }

  /// 处理发送消息
  Future<void> _handleSendMessage(
    String message,
    AIProvider? provider,
    Emitter<StandaloneChatState> emit,
  ) async {
    debugPrint('🚀🚀🚀 _handleSendMessage 被调用！消息: "$message", 提供商: ${provider?.displayName}');
    if (message.trim().isEmpty) return;

    // 确定使用的AI提供商
    debugPrint('🔍 提供商选择: provider=$provider, state.selectedProvider=${state.selectedProvider}, configService.currentProvider=${_configService.currentProvider}');
    final selectedProvider = provider ?? 
        state.selectedProvider ?? 
        _configService.currentProvider;
    debugPrint('✅ 最终选择的提供商: ${selectedProvider.displayName}');

    // 生成消息ID
    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentMessageId = '${DateTime.now().millisecondsSinceEpoch + 1}'; // AI消息ID

    // 添加用户消息
    final userMessage = ChatMessage(
      id: userMessageId,
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 先更新UI状态，显示用户消息
    if (!emit.isDone) {
      emit(state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        isStreaming: true,
        error: null,
        selectedProvider: selectedProvider,
        currentStreamingMessage: '',
      ));
      debugPrint('✅ 用户消息已添加到UI');
    }

    try {
      // 保存用户消息到数据库
      await _persistence.saveMessage(userMessage);
      debugPrint('📝 用户消息已保存到数据库');
    } catch (e) {
      debugPrint('❌ 保存用户消息失败: $e');
    }

    debugPrint('🎯 准备进入AI服务调用try块');
    debugPrint('🔍 选中的提供商: ${selectedProvider.displayName}');
    
    // 使用 unawaited 来防止阻塞事件处理器
    debugPrint('⚡ 开始异步调用AI服务...');
    unawaited(_callAIServiceAsync(message, selectedProvider));
  }

  /// 异步调用AI服务，避免阻塞事件处理器
  Future<void> _callAIServiceAsync(String message, AIProvider selectedProvider) async {
    debugPrint('🌟 _callAIServiceAsync 方法被调用！');
    try {
      // 开始AI流式响应
      await _streamSubscription?.cancel();
      debugPrint('📡 流订阅已取消');
      
      debugPrint('🤖 准备调用AI服务: 消息="$message", 提供商=${selectedProvider.displayName}');
      
      await _aiService.sendMessage(
        message: message,
        provider: selectedProvider,
        onResponse: (response) {
          debugPrint('📨 收到AI响应片段: $response');
          add(StandaloneChatEvent.receiveStreamChunk(chunk: response));
        },
        onError: (error) {
          debugPrint('❌ AI响应错误: $error');
          add(StandaloneChatEvent.errorOccurred(error: error));
        },
      );
      
      // 发送完成事件
      debugPrint('✅ AI服务调用完成，发送完成事件');
      add(const StandaloneChatEvent.finishResponse());
    } catch (e) {
      debugPrint('❌ AI服务调用异常: $e');
      add(StandaloneChatEvent.errorOccurred(error: e.toString()));
    }
  }

  /// 处理接收流式数据块
  void _handleReceiveStreamChunk(
    String chunk,
    Emitter<StandaloneChatState> emit,
  ) {
    if (emit.isDone) return;
    
    final currentContent = state.currentStreamingMessage ?? '';
    final newContent = currentContent + chunk;

    emit(state.copyWith(
      currentStreamingMessage: newContent,
      isStreaming: true,
    ));
  }

  /// 处理完成响应
  Future<void> _handleFinishResponse(Emitter<StandaloneChatState> emit) async {
    if (emit.isDone) return;
    
    final streamingContent = state.currentStreamingMessage ?? '';
    
    if (streamingContent.isNotEmpty) {
      // 创建AI消息
      final aiMessage = ChatMessage(
        id: _currentMessageId,
        content: streamingContent,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: state.selectedProvider,
      );

      try {
        // 保存AI消息到数据库
        await _persistence.saveMessage(aiMessage);
      } catch (e) {
        debugPrint('保存AI消息失败: $e');
      }

      if (emit.isDone) return;
      
      // 更新状态
      emit(state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        isStreaming: false,
        currentStreamingMessage: null,
      ));
    } else {
      if (emit.isDone) return;
      
      emit(state.copyWith(
        isLoading: false,
        isStreaming: false,
        currentStreamingMessage: null,
      ));
    }
  }

  /// 处理错误
  void _handleErrorOccurred(
    String error,
    Emitter<StandaloneChatState> emit,
  ) {
    if (emit.isDone) return;
    
    emit(state.copyWith(
      isLoading: false,
      isStreaming: false,
      error: error,
      currentStreamingMessage: null,
    ));
  }

  /// 处理加载历史记录
  Future<void> _handleLoadHistory(Emitter<StandaloneChatState> emit) async {
    if (state.isHistoryLoaded) return;

    try {
      final historyMessages = await _persistence.loadMessages();
      
      
      if (emit.isDone) return;
      emit(state.copyWith(
        messages: historyMessages,
        isHistoryLoaded: true,
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        error: '加载历史记录失败: $e',
      ));
    }
  }

  /// 处理清空聊天
  Future<void> _handleClearChat(Emitter<StandaloneChatState> emit) async {
    try {
      await _persistence.clearMessages();
      if (emit.isDone) return;
      emit(state.copyWith(
        messages: [],
        error: null,
        currentStreamingMessage: null,
        isStreaming: false,
        isLoading: false,
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        error: '清空聊天失败: $e',
      ));
    }
  }

  /// 处理切换提供商
  void _handleChangeProvider(
    AIProvider provider,
    Emitter<StandaloneChatState> emit,
  ) {
    _configService.setProvider(provider);
    if (emit.isDone) return;
    emit(state.copyWith(
      selectedProvider: provider,
    ));
  }


  /// 处理加载聊天历史 - 与 loadHistory 相同
  Future<void> _handleLoadChatHistory(
    Emitter<StandaloneChatState> emit,
  ) async {
    await _handleLoadHistory(emit);
  }

  /// 处理加载聊天会话
  Future<void> _handleLoadChatSession(
    String sessionId,
    Emitter<StandaloneChatState> emit,
  ) async {
    // 独立聊天只有一个会话，直接加载历史
    await _handleLoadHistory(emit);
  }

  /// 处理创建新聊天会话
  Future<void> _handleCreateNewChatSession(
    Emitter<StandaloneChatState> emit,
  ) async {
    // 独立聊天只有一个会话，直接清空聊天
    await _handleClearChat(emit);
  }

  /// 处理重命名聊天会话
  Future<void> _handleRenameChatSession(
    String sessionId,
    String newTitle,
    Emitter<StandaloneChatState> emit,
  ) async {
    // 独立聊天不支持重命名，暂不实现
    debugPrint('独立聊天不支持重命名会话');
  }

  /// 处理删除聊天会话
  Future<void> _handleDeleteChatSessions(
    List<String> sessionIds,
    Emitter<StandaloneChatState> emit,
  ) async {
    // 独立聊天只有一个会话，相当于清空聊天
    await _handleClearChat(emit);
  }

  /// 处理清空所有聊天历史
  Future<void> _handleClearAllChatHistory(
    Emitter<StandaloneChatState> emit,
  ) async {
    await _handleClearChat(emit);
  }

  /// 处理导出聊天历史
  Future<void> _handleExportChatHistory(
    Emitter<StandaloneChatState> emit,
  ) async {
    // TODO: 实现聊天历史导出功能
    debugPrint('导出聊天历史功能暂未实现');
  }

  /// 处理重试消息
  Future<void> _handleRetryMessage(
    String messageId,
    Emitter<StandaloneChatState> emit,
  ) async {
    // TODO: 实现消息重试功能
    debugPrint('消息重试功能暂未实现');
  }

  /// 处理编辑消息
  Future<void> _handleEditMessage(
    String messageId,
    String newContent,
    Emitter<StandaloneChatState> emit,
  ) async {
    // TODO: 实现消息编辑功能
    debugPrint('消息编辑功能暂未实现');
  }

}

/// 扩展方法
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}
