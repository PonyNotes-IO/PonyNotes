import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy/plugins/standalone_ai_chat/application/standalone_chat_bloc.dart';
import 'package:appflowy/plugins/standalone_ai_chat/models/chat_image.dart';
import 'package:appflowy/plugins/standalone_ai_chat/services/image_storage_service.dart';
import 'package:appflowy/plugins/standalone_ai_chat/presentation/widgets/chat_image_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 聊天消息气泡组件
/// 支持用户消息和AI回复的不同样式显示
class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRetry,
    this.onEdit,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: widget.message.isUser
            ? _buildUserMessage()
            : _buildAiMessage(),
      ),
    );
  }

  /// 构建用户消息
  Widget _buildUserMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isHovered) _buildActionButtons(isUser: true),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[500],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 显示图片
                if (widget.message.imageIds.isNotEmpty)
                  _buildMessageImages(),
                
                // 显示文本内容
                if (widget.message.content.isNotEmpty)
                  Text(
                    widget.message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildUserAvatar(),
      ],
    );
  }

  /// 构建AI消息
  Widget _buildAiMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiAvatar(),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI标识和提供商信息
              if (widget.message.aiProvider != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${widget.message.aiProvider!.displayName} AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // 消息内容
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: Colors.grey[200] ?? Colors.grey),
                ),
                child: _buildAiMessageContent(),
              ),
              // 消息状态和时间戳
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTimestamp(widget.message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (_isHovered) _buildActionButtons(isUser: false),
      ],
    );
  }

  /// 构建AI消息内容（支持流式显示和Markdown渲染）
  Widget _buildAiMessageContent() {
    if (widget.message.isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _buildMarkdownContent(widget.message.content),
          ),
          const SizedBox(width: 4),
          _buildTypingIndicator(),
        ],
      );
    }

    if (widget.message.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red[400],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.content,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    return _buildMarkdownContent(widget.message.content);
  }

  /// 构建Markdown内容
  Widget _buildMarkdownContent(String content) {
    print('🔍 [DEBUG] 使用flutter_markdown渲染内容');
    print('📄 [DEBUG] 内容预览: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."');
    print('📏 [DEBUG] 内容长度: ${content.length}');
    print('🎯 [DEBUG] 是否包含Markdown语法: ${content.contains('**') || content.contains('#') || content.contains('*')}');
    
    // 使用flutter_markdown替代markdown_widget
    return Markdown(
      data: content,
      shrinkWrap: true,
      selectable: true,
      padding: EdgeInsets.zero,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.4,
        ),
        h1: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        h2: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        h3: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        ),
        listBullet: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        code: TextStyle(
          backgroundColor: Colors.grey.shade200,
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.black87,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        codeblockPadding: const EdgeInsets.all(8),
      ),
    );
  }


  /// 构建打字指示器
  Widget _buildTypingIndicator() {
    return Container(
      width: 16,
      height: 16,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  /// 构建用户头像
  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  /// 构建AI头像
  Widget _buildAiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/ai_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.smart_toy,
              size: 20,
              color: Colors.grey[600],
            );
          },
        ),
      ),
    );
  }

  /// 构建操作按钮组
  Widget _buildActionButtons({required bool isUser}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 复制按钮
        _buildActionButton(
          icon: Icons.copy,
          tooltip: '复制',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已复制到剪贴板'),
                duration: Duration(seconds: 1),
              ),
            );
            widget.onCopy?.call();
          },
        ),
        const SizedBox(width: 4),
        // 重试按钮（仅AI消息显示）
        if (!isUser && (widget.message.hasError || widget.onRetry != null))
          _buildActionButton(
            icon: Icons.refresh,
            tooltip: '重试',
            onPressed: widget.onRetry,
          ),
        // 编辑按钮（仅用户消息显示）
        if (isUser && widget.onEdit != null) ...[
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.edit,
            tooltip: '编辑',
            onPressed: widget.onEdit,
          ),
        ],
      ],
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 构建消息中的图片
  Widget _buildMessageImages() {
    return FutureBuilder<List<ChatImage>>(
      future: _loadMessageImages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '图片加载失败',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          );
        }

        final images = snapshot.data!;
        return Container(
          margin: EdgeInsets.only(bottom: widget.message.content.isNotEmpty ? 8 : 0),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: images.map((image) => ChatImageWidget(
              image: image,
              width: 120,
              height: 120,
              onTap: () => _showImagePreview(context, image),
            )).toList(),
          ),
        );
      },
    );
  }

  /// 加载消息中的图片
  Future<List<ChatImage>> _loadMessageImages() async {
    final imageStorage = ImageStorageService.instance;
    await imageStorage.initialize();
    return await imageStorage.getImages(widget.message.imageIds);
  }

  /// 显示图片预览
  void _showImagePreview(BuildContext context, ChatImage image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ChatImageWidget(
            image: image,
            borderRadius: 0,
          ),
        ),
      ),
    );
  }
}

/// 消息加载指示器组件
class MessageLoadingIndicator extends StatelessWidget {
  const MessageLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(
              Icons.smart_toy,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          // 加载动画
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI正在思考中...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
