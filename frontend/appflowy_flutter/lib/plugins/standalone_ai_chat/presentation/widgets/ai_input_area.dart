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
                _buildToolButton('https://lanhu-oss-proxy.lanhuapp.com/SketchPngb009e2180e4e063d23918466aa2bbf13ded841feae872f7502028c5b6266bf43'),
                const SizedBox(width: 20),
                _buildToolButton('https://lanhu-oss-proxy.lanhuapp.com/SketchPngab61380e5d8d96dc6cff467b74a22fb2e7a80b2c8bf73f163286ce2b6f8a3020'),
                const SizedBox(width: 20),
                _buildToolButton('https://lanhu-oss-proxy.lanhuapp.com/SketchPnge792a7d2f9ca27deed7f0213aec0ea8ee9643cb705391f7a8b13effe006a465e'),
                const SizedBox(width: 20),
                _buildToolButton('https://lanhu-oss-proxy.lanhuapp.com/SketchPng646c32c2be74fa2141223e1341156125dbfd0adca82e6fe30bd93e8c681d91bb'),
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
          Image.network(
            'https://lanhu-oss-proxy.lanhuapp.com/SketchPnge7d4267a0f2057379d9d0f8d6234e1360804562d48a66363b504f16f4993ff28',
            width: 12,
            height: 12,
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
      child: Image.network(
        imageUrl,
        width: AIWelcomeTheme.iconSize,
        height: AIWelcomeTheme.iconSize,
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Image.network(
        'https://lanhu-oss-proxy.lanhuapp.com/SketchPng4f176c3cdbd3190cbcfd326e7491c5ef1dba23882c9f64c555d237883b4d06f2',
        width: AIWelcomeTheme.sendButtonSize,
        height: AIWelcomeTheme.sendButtonSize,
      ),
    );
  }
}
