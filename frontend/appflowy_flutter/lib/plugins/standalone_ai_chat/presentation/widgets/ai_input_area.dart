import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appflowy/core/config/ai_config.dart';
import '../ai_welcome_theme.dart';
import '../../services/image_service.dart';
import '../../models/chat_image.dart';

/// AI欢迎页面的输入交互区域
/// 对应设计图中的 block_3 区域
class AIInputArea extends StatefulWidget {
  const AIInputArea({
    super.key,
    required this.onMessageSent,
  });

  final Function(String message, AIProvider? provider, List<ChatImage>? images) onMessageSent;

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
  
  // 图片选择相关状态
  final List<ChatImage> _selectedImages = [];
  final ChatImageService _imageService = ChatImageService.instance;

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
        // 默认选择豆包模型
        _selectedProvider = _availableProviders.firstWhere(
          (provider) => provider == AIProvider.doubao,
          orElse: () => _availableProviders.isNotEmpty ? _availableProviders.first : AIProvider.doubao,
        );
        if (_selectedProvider != null) {
          AIConfigService.instance.setProvider(_selectedProvider!);
        }
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    // 确保已选择模型提供商
    if (_selectedProvider == null) {
      // 优先选择豆包，如果豆包不可用则选择第一个可用提供商
      if (_availableProviders.isNotEmpty) {
        final doubaoProvider = _availableProviders.firstWhere(
          (provider) => provider == AIProvider.doubao,
          orElse: () => _availableProviders.first,
        );
        _selectProvider(doubaoProvider);
      } else {
        // TODO: 显示错误提示，需要配置AI模型
        return;
      }
    }

    // 清空输入框和图片
    _textController.clear();
    final images = List<ChatImage>.from(_selectedImages);
    _selectedImages.clear();
    
    // 回调通知切换到聊天界面，传递消息、选择的模型和图片
    widget.onMessageSent(text, _selectedProvider, images.isNotEmpty ? images : null);
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
        constraints: BoxConstraints(
          minHeight: AIWelcomeTheme.inputContainerHeight,
          maxHeight: _selectedImages.isNotEmpty ? 
            AIWelcomeTheme.inputContainerHeight + (_selectedImages.length <= 3 ? 80 : 140) : // 根据图片数量动态调整
            AIWelcomeTheme.inputContainerHeight,
        ),
        decoration: AIWelcomeTheme.inputContainerDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 选中图片预览区域
            if (_selectedImages.isNotEmpty) _buildImagePreviewArea(),
            // 输入文本区域（对应 text-wrapper_5）
            Expanded(
              child: Container(
                margin: AIWelcomeTheme.inputTextPadding,
                constraints: const BoxConstraints(
                  minHeight: 60, // 确保输入框有最小高度
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AIWelcomeTheme.placeholderStyle(context).copyWith(
                    color: AIWelcomeTheme.primaryTextColor(context),
                  ),
                  decoration: InputDecoration(
                    hintText: '在小马笔记可以问或找到每一件事…',
                    hintStyle: AIWelcomeTheme.placeholderStyle(context),
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
                  _buildImagePickerButton(),
                  const SizedBox(width: 22),
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
                    decoration: AIWelcomeTheme.dividerDecoration(context),
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
        decoration: AIWelcomeTheme.modelSelectorDecoration(context),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedProvider?.displayName ?? '选择模型',
                style: AIWelcomeTheme.modelSelectorStyle(context),
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
                    color: AIWelcomeTheme.secondaryTextColor(context),
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
            decoration: AIWelcomeTheme.dropdownDecoration(context),
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
                            ? AIWelcomeTheme.selectedItemColor(context)
                            : Colors.transparent,
                      ),
                      child: Text(
                        provider.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedProvider == provider
                              ? AIWelcomeTheme.selectedItemTextColor(context)
                              : AIWelcomeTheme.primaryTextColor(context),
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

  /// 选择图片
  Future<void> _selectImage() async {
    if (_isDropdownOpen) {
      _closeDropdown();
    }
    
    final image = await _imageService.showImagePickerDialog(context);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      
      // 选择图片后自动聚焦到输入框，确保用户可以继续输入文字
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  /// 移除选中的图片
  void _removeImage(ChatImage image) {
    setState(() {
      _selectedImages.remove(image);
    });
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
          width: AIWelcomeTheme.iconSize * 0.8,
          height: AIWelcomeTheme.iconSize * 0.8,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: AIWelcomeTheme.iconSize,
              height: AIWelcomeTheme.iconSize,
              decoration: BoxDecoration(
                color: AIWelcomeTheme.containerColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.image_not_supported,
                size: AIWelcomeTheme.iconSize * 0.6,
                color: AIWelcomeTheme.secondaryTextColor(context),
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
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AIWelcomeTheme.sendButtonSize / 2),
              ),
              child: Icon(
                Icons.send,
                size: AIWelcomeTheme.sendButtonSize * 0.6,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建图片选择按钮
  Widget _buildImagePickerButton() {
    return GestureDetector(
      onTap: _selectImage,
      child: Container(
        width: AIWelcomeTheme.iconSize,
        height: AIWelcomeTheme.iconSize,
        decoration: BoxDecoration(
          color: _selectedImages.isNotEmpty ? AIWelcomeTheme.selectedItemColor(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.image,
                size: AIWelcomeTheme.iconSize,
                color: _selectedImages.isNotEmpty ? AIWelcomeTheme.selectedItemTextColor(context) : AIWelcomeTheme.secondaryTextColor(context),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_selectedImages.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建图片预览区域
  Widget _buildImagePreviewArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: AIWelcomeTheme.imagePreviewAreaDecoration(context),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedImages.map((image) => _buildImagePreviewItem(image)).toList(),
      ),
    );
  }

  /// 构建单个图片预览项
  Widget _buildImagePreviewItem(ChatImage image) {
    return Container(
      width: 60,
      height: 60,
      decoration: AIWelcomeTheme.imagePreviewItemDecoration(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: _buildImageWidget(image),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => _removeImage(image),
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

  /// 构建图片显示组件
  Widget _buildImageWidget(ChatImage image) {
    if (image.bytes != null) {
      return Image.memory(
        image.bytes!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImageWidget(),
      );
    } else if (image.filePath != null) {
      return Image.file(
        File(image.filePath!),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImageWidget(),
      );
    } else if (image.url != null) {
      return Image.network(
        image.url!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImageWidget(),
      );
    }
    return _buildErrorImageWidget();
  }

  /// 构建错误图片显示
  Widget _buildErrorImageWidget() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AIWelcomeTheme.containerColor(context),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        Icons.broken_image,
        size: 30,
        color: AIWelcomeTheme.secondaryTextColor(context),
      ),
    );
  }
}