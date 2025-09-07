import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/standalone_ai_chat/standalone_ai_chat_page.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';

/// AI聊天对话框主体
class AIChatDialog extends StatelessWidget {
  const AIChatDialog({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景遮罩
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // 对话框主体
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: StandaloneAiChatPage(
                userProfile: userProfile,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// AI聊天叠加层（仅包含对话框）
class AIChatOverlay extends StatelessWidget {
  const AIChatOverlay({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    // 直接返回对话框主体，不包含标题栏
    return AIChatDialog(userProfile: userProfile);
  }
}

/// 显示AI聊天叠加层的函数
Future<void> showAIChatOverlay(BuildContext context, UserProfilePB userProfile) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => Material(
      type: MaterialType.transparency,
      child: AIChatOverlay(userProfile: userProfile),
    ),
  );
} 