import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/core/config/ai_config.dart';
import 'package:appflowy/plugins/standalone_ai_chat/application/standalone_chat_bloc.dart';

/// 聊天输入栏组件
/// 提供消息输入、发送、模型选择等功能
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    this.onSendMessage,
    this.enabled = true,
  });

  final Function(String message)? onSendMessage;
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _selectorKey = GlobalKey();
  
  // 状态变量
  AIProvider? _selectedProvider;
  bool _isDropdownOpen = false;
  bool _isMultiline = false;
  List<AIProvider> _availableProviders = [];
  OverlayEntry? _overlayEntry;
  
  // 输入限制
  static const int _maxLength = 2000;
  static const int _maxLines = 8;

  @override
  void initState() {
    super.initState();
    _loadAIConfig();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 加载AI配置
  Future<void> _loadAIConfig() async {
    await AIConfigService.instance.loadConfig();
    if (mounted) {
      setState(() {
        _availableProviders = AIConfigService.instance.getAvailableProviders();
        _selectedProvider = _availableProviders.isNotEmpty ? _availableProviders.first : null;
      });
    }
  }

  /// 文本变化监听
  void _onTextChanged() {
    final text = _textController.text;
    final shouldBeMultiline = text.contains('\n') || text.length > 50;
    
    if (_isMultiline != shouldBeMultiline) {
      setState(() {
        _isMultiline = shouldBeMultiline;
      });
    }
  }

  /// 焦点变化监听
  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _isDropdownOpen) {
      _closeDropdown();
    }
  }

  /// 发送消息
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || !widget.enabled) return;

    // 确保已选择模型提供商
    if (_selectedProvider == null) {
      _showError('请先选择AI模型');
      return;
    }

    // 检查消息长度
    if (text.length > _maxLength) {
      _showError('消息长度不能超过${_maxLength}个字符');
      return;
    }

    // 发送消息
    widget.onSendMessage?.call(text);
    
    // 发送到BLoC
    context.read<StandaloneChatBloc>().add(
      StandaloneChatEvent.sendMessage(
        message: text,
        provider: _selectedProvider,
      ),
    );

    // 清空输入框
    _textController.clear();
    setState(() {
      _isMultiline = false;
    });
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StandaloneChatBloc, StandaloneChatState>(
      listener: (context, state) {
        // 监听状态变化，更新UI
        if (state.error != null) {
          _showError(state.error!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Column(
          children: [
            // 输入区域
            _buildInputArea(),
            // 工具栏
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 60,
        maxHeight: _isMultiline ? 160 : 60,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 文本输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: widget.enabled,
                maxLength: _maxLength,
                maxLines: _isMultiline ? _maxLines : 1,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '', // 隐藏字符计数器
                ),
                onSubmitted: (_) {
                  if (!_isMultiline) {
                    _sendMessage();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 发送按钮
          _buildSendButton(),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 模型选择器
          _buildModelSelector(),
          const Spacer(),
          // 字符计数
          _buildCharacterCounter(),
          const SizedBox(width: 16),
          // 快捷键提示
          _buildShortcutHint(),
        ],
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton() {
    final canSend = _textController.text.trim().isNotEmpty && 
                   widget.enabled && 
                   _selectedProvider != null;

    return BlocBuilder<StandaloneChatBloc, StandaloneChatState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        
        return Container(
          width: 44,
          height: 44,
          child: Material(
            color: canSend && !isLoading ? Colors.blue[500] : Colors.grey[300],
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: canSend && !isLoading ? _sendMessage : null,
              borderRadius: BorderRadius.circular(22),
              child: Icon(
                isLoading ? Icons.stop : Icons.send,
                size: 20,
                color: canSend && !isLoading ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建模型选择器
  Widget _buildModelSelector() {
    return GestureDetector(
      key: _selectorKey,
      onTap: widget.enabled ? _toggleDropdown : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDropdownOpen ? Colors.blue[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              _selectedProvider?.displayName ?? '选择模型',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Transform.rotate(
              angle: _isDropdownOpen ? 3.14159 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建字符计数器
  Widget _buildCharacterCounter() {
    final count = _textController.text.length;
    final isNearLimit = count > _maxLength * 0.8;
    
    return Text(
      '$count/$_maxLength',
      style: TextStyle(
        fontSize: 11,
        color: isNearLimit ? Colors.orange[600] : Colors.grey[500],
        fontWeight: isNearLimit ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  /// 构建快捷键提示
  Widget _buildShortcutHint() {
    return Text(
      'Enter发送 • Shift+Enter换行',
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[500],
      ),
    );
  }

  /// 切换下拉框
  void _toggleDropdown() {
    if (_availableProviders.isEmpty) return;
    
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  /// 打开下拉框
  void _openDropdown() {
    if (_availableProviders.isEmpty) return;
    
    setState(() {
      _isDropdownOpen = true;
    });

    final RenderBox? selectorRenderBox = 
        _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (selectorRenderBox == null) return;
    
    final selectorOffset = selectorRenderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: selectorOffset.dx,
        bottom: MediaQuery.of(context).size.height - selectorOffset.dy + 4,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 200,
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _availableProviders.map((provider) {
                  return InkWell(
                    onTap: () => _selectProvider(provider),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedProvider == provider
                            ? Colors.blue[50]
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 16,
                            color: _selectedProvider == provider
                                ? Colors.blue[600]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedProvider == provider
                                    ? Colors.blue[700]
                                    : Colors.black87,
                                fontWeight: _selectedProvider == provider
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_selectedProvider == provider)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 关闭下拉框
  void _closeDropdown() {
    setState(() {
      _isDropdownOpen = false;
    });
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 选择提供商
  void _selectProvider(AIProvider provider) {
    setState(() {
      _selectedProvider = provider;
    });
    
    // 更新BLoC状态
    context.read<StandaloneChatBloc>().add(
      StandaloneChatEvent.changeProvider(provider: provider),
    );
    
    _closeDropdown();
  }
}

/// 输入建议组件
class InputSuggestions extends StatelessWidget {
  const InputSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return InkWell(
            onTap: () => onSuggestionTap(suggestion),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 快速操作按钮组件
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onActionTap,
  });

  final Function(String action) onActionTap;

  static const List<Map<String, dynamic>> _actions = [
    {'icon': Icons.lightbulb_outline, 'label': '创意灵感', 'action': 'creative'},
    {'icon': Icons.code, 'label': '代码助手', 'action': 'code'},
    {'icon': Icons.translate, 'label': '翻译', 'action': 'translate'},
    {'icon': Icons.summarize, 'label': '总结', 'action': 'summarize'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _actions.map((action) {
          return InkWell(
            onTap: () => onActionTap(action['action']),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    action['icon'],
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action['label'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
