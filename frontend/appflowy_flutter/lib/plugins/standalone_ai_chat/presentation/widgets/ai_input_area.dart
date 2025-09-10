import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import '../ai_welcome_theme.dart';

/// AI欢迎页面的输入交互区域
/// 对应设计图中的 block_3 区域
class AIInputArea extends StatefulWidget {
  const AIInputArea({
    super.key,
    required this.onMessageSent,
  });

  final VoidCallback onMessageSent;

  @override
  State<AIInputArea> createState() => _AIInputAreaState();
}

class _AIInputAreaState extends State<AIInputArea> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 发送消息到AI聊天
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(ChatEvent.sendMessage(message: text));

    // 清空输入框
    _textController.clear();
    
    // 回调通知切换到聊天界面
    widget.onMessageSent();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }

  /// 构建模型选择下拉框
  Widget _buildModelSelector() {
    return Container(
      width: 92,
      height: AIWelcomeTheme.toolbarButtonSize,
      decoration: AIWelcomeTheme.modelSelectorDecoration,
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Text(
            '选择模型',
            style: AIWelcomeTheme.modelSelectorStyle,
          ),
          const Spacer(),
          Image.asset(
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
          const SizedBox(width: 10),
        ],
      ),
    );
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
