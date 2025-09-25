import 'package:flutter/material.dart';
import 'package:appflowy/core/config/ai_config.dart';
import 'widgets/ai_welcome_header.dart';
import 'widgets/ai_input_area.dart';
import 'ai_welcome_theme.dart';
import '../models/chat_image.dart';

/// AI欢迎页面，对应设计图中的完整布局
/// 当没有聊天消息时显示此页面
class AIWelcomePage extends StatelessWidget {
  const AIWelcomePage({
    super.key,
    required this.onMessageSent,
  });

  final Function(String message, AIProvider? provider, List<ChatImage>? images) onMessageSent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AIWelcomeTheme.backgroundColor(context),
      body: Column(
        children: [
          // 顶部头像和欢迎文字区域
          const AIWelcomeHeader(),
          // 输入交互区域
          AIInputArea(
            onMessageSent: onMessageSent,
          ),
          const Spacer(),
          // 底部提示文字（对应 text_18）
          Container(
            margin: const EdgeInsets.only(bottom: 64),
            child: Text(
              '内容由 AI 生成，请仔细甄别',
              style: AIWelcomeTheme.tooltipStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
