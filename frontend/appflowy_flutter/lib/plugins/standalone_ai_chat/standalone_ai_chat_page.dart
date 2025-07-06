import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_member_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_footer.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_welcome_page.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanoid/nanoid.dart';

class StandaloneAiChatPage extends StatelessWidget {
  const StandaloneAiChatPage({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB? userProfile;

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // 生成一个独立的聊天ID
    final chatId = 'standalone_chat_${nanoid()}';

    // 创建一个虚拟的ViewPB用于聊天组件
    final virtualView = ViewPB()
      ..id = chatId
      ..name = '问AI'
      ..layout = ViewLayoutPB.Chat;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(
            chatId: chatId,
            userId: userProfile!.id.toString(),
          ),
        ),
        BlocProvider(
          create: (_) => AIPromptInputBloc(
            objectId: chatId,
            predefinedFormat: PredefinedFormat(
              imageFormat: ImageFormat.text,
              textFormat: TextFormat.bulletList,
            ),
          ),
        ),
        BlocProvider(
          create: (_) => ChatSelectMessageBloc(
            viewNotifier: ViewPluginNotifier(view: virtualView),
          ),
        ),
        BlocProvider(create: (_) => ChatMemberBloc()),
      ],
      child: _buildChatInterface(context, virtualView),
    );
  }

  Widget _buildChatInterface(BuildContext context, ViewPB view) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 784),
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 784 ? 40 : 16,
      ),
      child: Column(
        children: [
          // 消息区域
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final chatBloc = context.read<ChatBloc>();

                // 如果没有消息，显示欢迎页面
                if (chatBloc.chatController.messages.isEmpty) {
                  return ChatWelcomePage(
                    userProfile: userProfile!,
                    onSelectedQuestion: (question) {
                      final aiPromptInputBloc =
                          context.read<AIPromptInputBloc>();
                      final showPredefinedFormats =
                          aiPromptInputBloc.state.showPredefinedFormats;
                      final predefinedFormat =
                          aiPromptInputBloc.state.predefinedFormat;

                      chatBloc.add(
                        ChatEvent.sendMessage(
                          message: question,
                          format:
                              showPredefinedFormats ? predefinedFormat : null,
                        ),
                      );
                    },
                  );
                }

                // 如果有消息，暂时显示一个简单的消息显示
                return const Center(
                  child: Text('聊天消息将在这里显示'),
                );
              },
            ),
          ),

          // 聊天输入框
          ChatFooter(view: view),
        ],
      ),
    );
  }
}
