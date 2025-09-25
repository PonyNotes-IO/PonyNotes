import 'package:flutter/material.dart';
import '../ai_welcome_theme.dart';

/// AI欢迎页面顶部头像和文字区域
/// 对应设计图中的 block_1 区域
class AIWelcomeHeader extends StatelessWidget {
  const AIWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AIWelcomeTheme.welcomeAreaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像和主标题行（对应 block_1）
          Row(
            children: [
              // AI头像（对应 block_2 + group_1）
              Container(
                width: AIWelcomeTheme.avatarSize,
                height: AIWelcomeTheme.avatarSize,
                decoration: AIWelcomeTheme.avatarDecoration(context),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/ai_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AIWelcomeTheme.avatarBackgroundColor(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.smart_toy,
                          size: AIWelcomeTheme.avatarSize * 0.6,
                          color: AIWelcomeTheme.avatarIconColor(context),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20), // 头像和文字之间的间距
              // 主标题（对应 text_15）
              Expanded(
                child: Text(
                  '我是小马笔记AI，很高兴见到你！',
                  style: AIWelcomeTheme.titleStyle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // 主标题和副标题之间的间距
          // 副标题（对应 text_16）- 左对齐显示
          Text(
            '我可以帮你写代码、写作各种创意内容，请把你的任务交给我吧～',
            style: AIWelcomeTheme.subtitleStyle(context),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
