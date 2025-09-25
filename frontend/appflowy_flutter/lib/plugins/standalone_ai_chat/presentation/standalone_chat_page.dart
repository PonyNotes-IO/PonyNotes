import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy/core/config/ai_config.dart';
import '../application/standalone_chat_bloc.dart';
import '../services/image_service.dart';
import '../models/chat_image.dart';

/// 独立AI聊天页面视图
class StandaloneChatPageView extends StatelessWidget {
  const StandaloneChatPageView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
      Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        body: Column(
        children: [
          // 顶部状态栏
          _buildTopBar(context),
          // 消息列表区域
          Expanded(
            child: _ChatMessageList(
              userProfile: userProfile,
            ),
          ),
          // 底部输入区域
          _ChatInputBar(),
        ],
      ),
    );
  }

      /// 构建顶部状态栏
    Widget _buildTopBar(BuildContext context) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
      child: BlocBuilder<StandaloneChatBloc, StandaloneChatState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // AI头像
                                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                const SizedBox(width: 12),
                // 标题和状态
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                              Text(
                          '小马笔记AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      Text(
                        _getStatusText(state),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 模型选择器
                _buildModelSelector(context, state),
                const SizedBox(width: 8),
                // 更多操作按钮
                _buildMoreButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 获取状态文本
  String _getStatusText(StandaloneChatState state) {
    if (state.isStreaming) {
      return '正在思考中...';
    } else if (state.error != null) {
      return '连接异常';
    } else if (state.selectedProvider != null) {
      return '使用 ${state.selectedProvider!.displayName}';
    } else {
      return '选择AI模型开始对话';
    }
  }

  /// 构建模型选择器
  Widget _buildModelSelector(BuildContext context, StandaloneChatState state) {
    final availableProviders = AIConfigService.instance.getAvailableProviders();
    
    if (availableProviders.isEmpty) {
              return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.error),
          ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 14, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 4),
            Text(
              '未配置',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<AIProvider>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: Colors.blue[600]),
            const SizedBox(width: 4),
            Text(
              state.selectedProvider?.displayName ?? '选择模型',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
      onSelected: (provider) {
        context.read<StandaloneChatBloc>().add(
          StandaloneChatEvent.changeProvider(provider: provider),
        );
      },
      itemBuilder: (context) {
        return availableProviders.map((provider) {
          final isSelected = state.selectedProvider == provider;
          return PopupMenuItem<AIProvider>(
            value: provider,
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.displayName,
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  /// 构建更多操作按钮
  Widget _buildMoreButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onSelected: (value) => _handleMoreAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.clear_all, size: 16),
              SizedBox(width: 8),
              Text('清空对话'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download, size: 16),
              SizedBox(width: 8),
              Text('导出记录'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 16),
              SizedBox(width: 8),
              Text('AI设置'),
            ],
          ),
        ),
      ],
    );
  }

  /// 处理更多操作
  void _handleMoreAction(BuildContext context, String action) {
    final bloc = context.read<StandaloneChatBloc>();
    
    switch (action) {
      case 'clear':
        _showClearConfirmation(context, bloc);
        break;
      case 'export':
        _exportChat(context);
        break;
      case 'settings':
        _showSettings(context);
        break;
    }
  }

  /// 显示清空确认对话框
  void _showClearConfirmation(BuildContext context, StandaloneChatBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空对话'),
        content: const Text('确定要清空所有对话记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(const StandaloneChatEvent.clearChat());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 导出聊天记录
  void _exportChat(BuildContext context) {
    // TODO: 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中...')),
    );
  }

  /// 显示设置页面
  void _showSettings(BuildContext context) {
    // TODO: 实现设置页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置页面开发中...')),
    );
  }
}

/// 简化的聊天输入栏
class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar();

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;
  final List<ChatImage> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateSendButtonState);
  }

  @override
  void dispose() {
    _textController.removeListener(_updateSendButtonState);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSendButtonState() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;
    final canSend = hasText || hasImages;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    final hasText = text.isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;
    
    if (!hasText && !hasImages) return;

    final bloc = context.read<StandaloneChatBloc>();
    
    if (hasImages) {
      bloc.add(StandaloneChatEvent.sendMessageWithImages(
        message: text,
        images: List.from(_selectedImages),
      ));
    } else {
      bloc.add(StandaloneChatEvent.sendMessage(message: text));
    }

    _textController.clear();
    _selectedImages.clear();
    _updateSendButtonState();
  }

  /// 停止AI流式输出
  void _stopStreaming() {
    final bloc = context.read<StandaloneChatBloc>();
    bloc.add(const StandaloneChatEvent.stopStreaming());
  }

  /// 选择图片
  Future<void> _selectImage() async {
    final imageService = ChatImageService.instance;
    final image = await imageService.showImagePickerDialog(context);
    
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      _updateSendButtonState();
    }
  }

  /// 移除选中的图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _updateSendButtonState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StandaloneChatBloc, StandaloneChatState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 显示选中的图片
                  if (_selectedImages.isNotEmpty) _buildSelectedImages(),
                  // 输入框和按钮
                                      Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    child: Row(
                      children: [
                        // 图片按钮
                        _buildImageButton(state),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            enabled: !state.isLoading && state.selectedProvider != null,
                            maxLines: 5,
                            minLines: 1,
                                                          decoration: InputDecoration(
                                hintText: _getHintText(state),
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 14
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (!state.isLoading && state.selectedProvider != null) ? (_) => _sendMessage() : null,
                          ),
                        ),
                        _buildSendButton(state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getHintText(StandaloneChatState state) {
    debugPrint('🔍 _getHintText: isLoading=${state.isLoading}, isStreaming=${state.isStreaming}, selectedProvider=${state.selectedProvider?.displayName}');
    if (state.selectedProvider == null) {
      return '请先选择AI模型...';
    } else if (state.isLoading) {
      debugPrint('💭 显示"AI正在思考中..."');
      return 'AI正在思考中...';
    } else {
      debugPrint('✏️ 显示"输入您的问题..."');
      return '输入您的问题...';
    }
  }

  /// 构建图片按钮
  Widget _buildImageButton(StandaloneChatState state) {
    final isEnabled = !state.isLoading && state.selectedProvider != null;
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: isEnabled ? _selectImage : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isEnabled 
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.image,
            size: 16,
            color: isEnabled 
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          ),
        ),
      ),
    );
  }

  /// 构建选中的图片列表
  Widget _buildSelectedImages() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _selectedImages
              .asMap()
              .entries
              .map((entry) => _buildImagePreview(entry.key, entry.value))
              .toList(),
        ),
      ),
    );
  }

  /// 构建图片预览
  Widget _buildImagePreview(int index, ChatImage image) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image.bytes != null
                  ? Image.memory(
                      image.bytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    )
                  : image.filePath != null
                      ? Image.file(
                          File(image.filePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        )
                      : Icon(
                          Icons.image,
                          color: Colors.grey[400],
                        ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(StandaloneChatState state) {
    // 如果正在流式输出，显示停止按钮
    if (state.isStreaming) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => _stopStreaming(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.stop,
              size: 16,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      );
    }

    // 如果正在加载但不是流式输出，显示加载指示器
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    // 正常情况下显示发送按钮
    final isEnabled = !state.isLoading && state.selectedProvider != null && _canSend;
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: isEnabled ? _sendMessage : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isEnabled 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.send,
            size: 16,
            color: isEnabled 
                ? Theme.of(context).colorScheme.onPrimary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          ),
        ),
      ),
    );
  }
}

/// 简化的聊天消息列表
class _ChatMessageList extends StatefulWidget {
  const _ChatMessageList({required this.userProfile});

  final UserProfilePB userProfile;

  @override
  State<_ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<_ChatMessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StandaloneChatBloc, StandaloneChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state.messages.isEmpty && !state.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '开始与AI对话',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '在下方输入框中输入您的问题\n我会尽力为您提供帮助',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: state.messages.length + (state.isStreaming ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < state.messages.length) {
                final message = state.messages[index];
                return _buildMessageBubble(message, index == state.messages.length - 1 && !state.isStreaming);
              } else if (state.isStreaming && state.currentStreamingMessage != null) {
                final streamingMessage = ChatMessage(
                  id: 'streaming',
                  content: state.currentStreamingMessage!,
                  isUser: false,
                  timestamp: DateTime.now(),
                  aiProvider: state.selectedProvider,
                  isStreaming: true,
                );
                return _buildMessageBubble(streamingMessage, true, isStreaming: true);
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isLast, {bool isStreaming = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 16 : 8, top: 4),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.onPrimary
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      topLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                      topRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: message.isUser ? null : Border.all(
                      color: Theme.of(context).colorScheme.outline
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message.isUser 
                    ?                       SelectableText(
                        message.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : _buildMarkdownContent(message.content),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.onPrimaryContainer
                  ),
                ),
              ],
            ],
          ),
          // 为AI消息添加复制按钮
          if (!message.isUser && !isStreaming && message.content.trim().isNotEmpty)
            _buildCopyButton(message),
        ],
      ),
    );
  }

  /// 构建复制按钮
  Widget _buildCopyButton(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(left: 44, top: 6), // 44 = 32 (avatar) + 12 (spacing)
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _copyToClipboard(message.content),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '复制',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      
      // 显示复制成功的提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('已复制到剪贴板'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      // 复制失败时的处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('复制失败'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  /// 构建Markdown内容
  Widget _buildMarkdownContent(String content) {
    return Builder(
      builder: (context) => Markdown(
        data: content,
        shrinkWrap: true,
        selectable: true,
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            height: 1.4,
          ),
          h1: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          h2: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          h3: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          em: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          listBullet: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          code: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            fontFamily: 'monospace',
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          codeblockDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          codeblockPadding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}
