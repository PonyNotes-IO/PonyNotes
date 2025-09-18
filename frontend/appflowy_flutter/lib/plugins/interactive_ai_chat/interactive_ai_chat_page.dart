import 'dart:async';

import 'package:appflowy/core/config/ai_config.dart';
import 'package:appflowy/core/services/ai_chat_service.dart';
import 'package:appflowy/plugins/ai_chat/presentation/widgets/ai_model_selector.dart';
import 'package:appflowy/plugins/standalone_ai_chat/services/image_service.dart';
import 'package:appflowy/plugins/standalone_ai_chat/models/chat_image.dart';
import 'package:appflowy/plugins/standalone_ai_chat/presentation/widgets/chat_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 交互式AI聊天页面 - 真正可以与AI进行对话
class InteractiveAIChatPage extends StatefulWidget {
  const InteractiveAIChatPage({
    super.key,
    this.initialMessage,
  });

  final String? initialMessage;

  @override
  State<InteractiveAIChatPage> createState() => _InteractiveAIChatPageState();
}

class _InteractiveAIChatPageState extends State<InteractiveAIChatPage> {
  final AIChatService _chatService = AIChatService.instance;
  final AIConfigService _configService = AIConfigService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatImage> _selectedImages = [];
  final ChatImageService _imageService = ChatImageService.instance;
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription<String>? _streamSubscription;
  ChatMessage? _currentStreamingMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _chatService.initialize();
      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '初始化AI服务失败: $e';
        _isInitialized = true;
      });
    }
  }

  /// 处理图片选择
  Future<void> _handleImagePicker() async {
    try {
      final image = await _imageService.showImagePickerDialog(context);
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      debugPrint('选择图片时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 移除选中的图片
  void _removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initializeServices();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        toolbarHeight: 70, // 增加AppBar高度
        centerTitle: true, // 居中标题
        titleSpacing: 0, // 调整标题间距
        leadingWidth: 56, // 设置leading区域宽度
        leading: Container(
          margin: const EdgeInsets.only(top: 40), // 向下移动返回按钮
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '返回',
          ),
        ),
        title: Container(
          margin: const EdgeInsets.only(top: 40), // 向下移动标题
          child: const Text('AI聊天'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 40, right: 20), // 向下移动刷新按钮
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reloadConfig,
              tooltip: '重新加载配置',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 40, right: 20), // 向下移动清空按钮
            child: IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearMessages,
              tooltip: '清空对话',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI模型选择器
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
            ),
            child: AIModelSelector(
              selectedProvider: _configService.currentProvider,
              onProviderChanged: (provider) {
                setState(() {
                  // 切换提供商后清空消息历史
                  _messages.clear();
                });
              },
              showTestButton: true,
              onSettingsPressed: _showConfigHelp,
            ),
          ),
          
          // 聊天消息列表
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // 输入框
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '开始与AI对话',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入消息并发送，体验真实的AI交互',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickStartChip('你好，请介绍一下自己'),
              _buildQuickStartChip('帮我写一段代码'),
              _buildQuickStartChip('解释一下Flutter'),
              _buildQuickStartChip('今天天气怎么样？'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.smart_toy, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                  ? theme.primaryColor
                  : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: isUser 
                  ? null 
                  : Border.all(color: theme.dividerColor.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUser ? Colors.white : theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser 
                            ? Colors.white.withOpacity(0.7)
                            : theme.hintColor,
                        ),
                      ),
                      if (!isUser && !message.isStreaming) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyToClipboard(message.content),
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 20, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          // 图片预览区域
          if (_selectedImages.isNotEmpty)
            ChatImagePreview(
              images: _selectedImages,
              onRemove: (image) {
                final index = _selectedImages.indexOf(image);
                if (index != -1) {
                  _removeImage(index);
                }
              },
            ),
          
          // 输入框和按钮区域
          Row(
            children: [
              // 图片选择按钮
              IconButton(
                onPressed: _isLoading ? null : _handleImagePicker,
                icon: Icon(
                  Icons.image,
                  color: _isLoading ? theme.disabledColor : theme.primaryColor,
                ),
                tooltip: '选择图片',
              ),
              
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _isLoading 
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          width: 24,
                          height: 24,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: _isLoading ? _stopStreaming : _sendMessage,
                backgroundColor: _isLoading ? Colors.red : theme.primaryColor,
                child: Icon(
                  _isLoading ? Icons.stop : Icons.send,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final hasImages = _selectedImages.isNotEmpty;
    
    if (text.isEmpty && !hasImages) return;
    if (_isLoading) return;

    // 构建消息内容，包含图片信息
    String messageContent = text;
    if (hasImages) {
      if (text.isNotEmpty) {
        messageContent += '\n\n';
      }
      messageContent += '[包含 ${_selectedImages.length} 张图片，请分析这些图片]';
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        messageContent += '\n- 图片${i + 1}: ${image.name ?? '未知'} (${image.fileSizeFormatted})';
      }
    }

    // 添加用户消息
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: messageContent,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      // 清空输入框和选中的图片
      _selectedImages.clear();
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 创建AI消息占位符
      final aiMessage = ChatMessage(
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );

      setState(() {
        _messages.add(aiMessage);
        _currentStreamingMessage = aiMessage;
      });

      _scrollToBottom();

      // 发送消息到AI
      final response = await _chatService.sendMessage(
        message: text,
        conversationHistory: _messages
            .where((m) => m != userMessage && m != aiMessage)
            .map((m) => AIChatMessage(
                  role: m.role == MessageRole.user ? 'user' : 'assistant',
                  content: m.content,
                  timestamp: m.timestamp,
                ))
            .toList(),
      );

      if (response.hasError) {
        // 更新为错误消息
        final index = _messages.indexOf(aiMessage);
        if (index != -1) {
          setState(() {
            _messages[index] = ChatMessage(
              role: MessageRole.assistant,
              content: '❌ ${response.error}',
              timestamp: DateTime.now(),
            );
          });
        }
      } else {
        // 更新为AI回复
        final index = _messages.indexOf(aiMessage);
        if (index != -1) {
          setState(() {
            _messages[index] = ChatMessage(
              role: MessageRole.assistant,
              content: response.content,
              timestamp: DateTime.now(),
            );
          });
        }
      }
    } catch (e) {
      final aiMessage = ChatMessage(
        role: MessageRole.assistant,
        content: '❌ 发送消息时出错: $e',
        timestamp: DateTime.now(),
      );

      if (_currentStreamingMessage != null) {
        final index = _messages.indexOf(_currentStreamingMessage!);
        if (index != -1) {
          setState(() {
            _messages[index] = aiMessage;
          });
        }
      } else {
        setState(() {
          _messages.add(aiMessage);
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
        _currentStreamingMessage = null;
      });
      _scrollToBottom();
    }
  }

  void _stopStreaming() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    
    if (_currentStreamingMessage != null) {
      final index = _messages.indexOf(_currentStreamingMessage!);
      if (index != -1) {
        setState(() {
          _messages[index] = ChatMessage(
            role: MessageRole.assistant,
            content: _currentStreamingMessage!.content + '\n\n[已停止生成]',
            timestamp: _currentStreamingMessage!.timestamp,
          );
        });
      }
    }

    setState(() {
      _isLoading = false;
      _currentStreamingMessage = null;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }

  Future<void> _reloadConfig() async {
    await _configService.reloadConfig();
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 配置已重新加载'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showConfigHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI配置帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('要使用AI功能，请按以下步骤配置：'),
              SizedBox(height: 12),
              Text('1. 复制配置文件：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('   cp ai_config_example.env .env.ai'),
              SizedBox(height: 8),
              Text('2. 编辑 .env.ai 文件，填入您的API密钥：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('   • DeepSeek: https://platform.deepseek.com/'),
              Text('   • 通义千问: https://dashscope.console.aliyun.com/'),
              Text('   • 豆包: https://console.volcengine.com/ark/'),
              SizedBox(height: 8),
              Text('3. 重启应用以加载新配置', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('注意：.env.ai 文件已被添加到 .gitignore，不会被提交到版本控制。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

/// 聊天消息数据模型
class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });
}

/// 消息角色枚举
enum MessageRole {
  user,
  assistant,
}
