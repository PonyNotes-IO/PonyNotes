import 'package:flutter/material.dart';
import 'package:appflowy/core/config/ai_config.dart';
import '../ai_welcome_theme.dart';

/// AI欢迎页面的输入交互区域
/// 对应设计图中的 block_3 区域
class AIInputArea extends StatefulWidget {
  const AIInputArea({
    super.key,
    required this.onMessageSent,
  });

  final Function(String message, AIProvider? provider) onMessageSent;

  @override
  State<AIInputArea> createState() => _AIInputAreaState();
}

class _AIInputAreaState extends State<AIInputArea> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _selectorKey = GlobalKey(); // 用于获取模型选择器位置
  
  // 模型选择相关状态
  AIProvider? _selectedProvider; // 初始化为null，显示"选择模型"
  bool _isDropdownOpen = false;
  List<AIProvider> _availableProviders = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadAIConfig();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
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
        // 不设置默认选中的提供商，保持为null以显示"选择模型"
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 确保已选择模型提供商
    if (_selectedProvider == null) {
      // 如果有可用提供商，选择第一个作为默认
      if (_availableProviders.isNotEmpty) {
        _selectProvider(_availableProviders.first);
      } else {
        // TODO: 显示错误提示，需要配置AI模型
        return;
      }
    }

    // 清空输入框
    _textController.clear();
    
    // 回调通知切换到聊天界面，传递消息和选择的模型
    widget.onMessageSent(text, _selectedProvider);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击其他区域时关闭下拉框
        if (_isDropdownOpen) {
          _closeDropdown();
        }
      },
      child: Container(
        margin: AIWelcomeTheme.inputContainerPadding,
        width: AIWelcomeTheme.inputContainerWidth,
        height: AIWelcomeTheme.inputContainerHeight,
        decoration: AIWelcomeTheme.inputContainerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入文本区域（对应 text-wrapper_5）
            Expanded(
              child: Container(
                margin: AIWelcomeTheme.inputTextPadding,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AIWelcomeTheme.placeholderStyle.copyWith(
                    color: AIWelcomeTheme.primaryTextColor,
                  ),
                  decoration: const InputDecoration(
                    hintText: '在小马笔记可以问或找到每一件事…',
                    hintStyle: AIWelcomeTheme.placeholderStyle,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            // 工具栏区域（对应 group_2）
            Container(
              margin: AIWelcomeTheme.toolbarPadding,
              width: AIWelcomeTheme.toolbarWidth,
              height: AIWelcomeTheme.toolbarHeight,
              child: Row(
                children: [
                  // 模型选择下拉框（对应 block_4）
                  _buildModelSelector(),
                  const Spacer(),
                  // 功能图标按钮组
                  _buildToolButton('assets/images/icons/tool_1.png'),
                  const SizedBox(width: 20),
                  _buildToolButton('assets/images/icons/tool_2.png'),
                  const SizedBox(width: 20),
                  _buildToolButton('assets/images/icons/tool_3.png'),
                  const SizedBox(width: 20),
                  _buildToolButton('assets/images/icons/tool_4.png'),
                  const SizedBox(width: 21),
                  // 分隔线（对应 block_5）
                  Container(
                    width: 1,
                    height: 20,
                    decoration: AIWelcomeTheme.dividerDecoration,
                  ),
                  const SizedBox(width: 20),
                  // 发送按钮（对应 label_9）
                  _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模型选择下拉框
  Widget _buildModelSelector() {
    return GestureDetector(
      key: _selectorKey, // 添加GlobalKey
      onTap: _toggleDropdown,
      child: Container(
        width: 130,
        height: AIWelcomeTheme.toolbarButtonSize,
        decoration: AIWelcomeTheme.modelSelectorDecoration,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedProvider?.displayName ?? '选择模型',
                style: AIWelcomeTheme.modelSelectorStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Transform.rotate(
              angle: _isDropdownOpen ? 3.14159 : 0, // 180度旋转
              child: Image.asset(
                'assets/images/icons/dropdown_arrow.png',
                width: 12,
                height: 12,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.arrow_drop_down,
                    size: 12,
                    color: Colors.grey[600],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  /// 切换下拉框状态
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

    // 使用GlobalKey获取模型选择器的准确位置
    final RenderBox? selectorRenderBox = _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (selectorRenderBox == null) return;
    
    final selectorSize = selectorRenderBox.size;
    final selectorOffset = selectorRenderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: selectorOffset.dx, // 与选择器左对齐
        top: selectorOffset.dy + selectorSize.height + 4, // 在选择器下方4px处
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 150, // 与选择器宽度一致
            constraints: const BoxConstraints(
              maxHeight: 200, // 最大高度限制
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _availableProviders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final provider = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == _availableProviders.length - 1;
                  
                  return InkWell(
                    onTap: () => _selectProvider(provider),
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(8) : Radius.zero,
                      bottom: isLast ? const Radius.circular(8) : Radius.zero,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedProvider == provider
                            ? Colors.blue[50]
                            : Colors.transparent,
                      ),
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
    AIConfigService.instance.setProvider(provider);
    _closeDropdown();
  }

  /// 构建工具按钮
  Widget _buildToolButton(String imageUrl) {
    return GestureDetector(
      onTap: () {
        // TODO: 实现具体的工具功能
      },
      child: Container(
        width: AIWelcomeTheme.iconSize,
        height: AIWelcomeTheme.iconSize,
        child: Image.asset(
          imageUrl,
          width: AIWelcomeTheme.iconSize,
          height: AIWelcomeTheme.iconSize,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: AIWelcomeTheme.iconSize,
              height: AIWelcomeTheme.iconSize,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.image_not_supported,
                size: AIWelcomeTheme.iconSize * 0.6,
                color: Colors.grey[600],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        width: AIWelcomeTheme.sendButtonSize,
        height: AIWelcomeTheme.sendButtonSize,
        child: Image.asset(
          'assets/images/icons/send_button.png',
          width: AIWelcomeTheme.sendButtonSize,
          height: AIWelcomeTheme.sendButtonSize,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: AIWelcomeTheme.sendButtonSize,
              height: AIWelcomeTheme.sendButtonSize,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(AIWelcomeTheme.sendButtonSize / 2),
              ),
              child: Icon(
                Icons.send,
                size: AIWelcomeTheme.sendButtonSize * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}