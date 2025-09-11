import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/standalone_ai_chat/application/standalone_chat_bloc.dart';
import 'chat_message_bubble.dart';

/// 聊天消息列表组件
/// 显示所有聊天消息，支持滚动、加载更多等功能
class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    this.onRetryMessage,
    this.onEditMessage,
  });

  final Function(ChatMessage)? onRetryMessage;
  final Function(ChatMessage)? onEditMessage;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听器
  void _onScroll() {
    // 如果用户手动滚动到顶部附近，禁用自动滚动
    final isNearTop = _scrollController.offset < 100;
    if (isNearTop && _autoScroll) {
      setState(() {
        _autoScroll = false;
      });
    }
    
    // 如果用户滚动到底部附近，启用自动滚动
    final isNearBottom = _scrollController.offset >= 
        _scrollController.position.maxScrollExtent - 100;
    if (isNearBottom && !_autoScroll) {
      setState(() {
        _autoScroll = true;
      });
    }
  }

  /// 滚动到底部
  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StandaloneChatBloc, StandaloneChatState>(
      listener: (context, state) {
        // 当有新消息时自动滚动到底部
        if (_autoScroll && state.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // 消息列表
            Expanded(
              child: _buildMessageList(state),
            ),
            // 底部工具栏
            if (!_autoScroll) _buildScrollToBottomButton(),
          ],
        );
      },
    );
  }

  /// 构建消息列表
  Widget _buildMessageList(StandaloneChatState state) {
    if (state.messages.isEmpty && !state.isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载指示器
        if (index == state.messages.length) {
          return const MessageLoadingIndicator();
        }

        final message = state.messages[index];
        return ChatMessageBubble(
          key: ValueKey(message.id),
          message: message,
          onCopy: () => _onMessageCopied(message),
          onRetry: message.hasError ? () => _onRetryMessage(message) : null,
          onEdit: message.isUser ? () => _onEditMessage(message) : null,
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有聊天记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始与AI对话吧！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建滚动到底部按钮
  Widget _buildScrollToBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FloatingActionButton.small(
        onPressed: () {
          setState(() {
            _autoScroll = true;
          });
          _scrollToBottom();
        },
        backgroundColor: Colors.blue[500],
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 处理消息复制
  void _onMessageCopied(ChatMessage message) {
    // 可以添加统计或其他逻辑
    debugPrint('消息已复制: ${message.id}');
  }

  /// 处理重试消息
  void _onRetryMessage(ChatMessage message) {
    widget.onRetryMessage?.call(message);
    
    // 发送重试事件到BLoC
    context.read<StandaloneChatBloc>().add(
      StandaloneChatEvent.retryMessage(messageId: message.id),
    );
  }

  /// 处理编辑消息
  void _onEditMessage(ChatMessage message) {
    widget.onEditMessage?.call(message);
    
    // 显示编辑对话框
    _showEditMessageDialog(message);
  }

  /// 显示编辑消息对话框
  void _showEditMessageDialog(ChatMessage message) {
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '请输入新的消息内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                // 发送编辑事件到BLoC
                context.read<StandaloneChatBloc>().add(
                  StandaloneChatEvent.editMessage(
                    messageId: message.id,
                    newContent: newContent,
                  ),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

/// 消息分组组件（按日期分组）
class MessageDateSeparator extends StatelessWidget {
  const MessageDateSeparator({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今天';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else if (now.difference(messageDate).inDays < 7) {
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}

/// 聊天统计信息组件
class ChatStatsWidget extends StatelessWidget {
  const ChatStatsWidget({
    super.key,
    required this.messageCount,
    required this.tokenCount,
  });

  final int messageCount;
  final int tokenCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem('消息', messageCount.toString()),
          const SizedBox(width: 24),
          _buildStatItem('Token', _formatTokenCount(tokenCount)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTokenCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
