import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_member_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_animation_list_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_footer.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/text_message_widget.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class StandaloneAiChatPage extends StatelessWidget {
  const StandaloneAiChatPage({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    // 生成一个聊天ID用于真实聊天数据
    final chatId = const Uuid().v4();

    // 创建一个真实的ViewPB用于聊天，不是虚拟的
    final view = ViewPB()
      ..id = chatId
      ..name = 'AI聊天'
      ..layout = ViewLayoutPB.Chat;

    // 创建ViewPluginNotifier
    final viewNotifier = ViewPluginNotifier(view: view);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(
            chatId: chatId,
            userId: userProfile.id.toString(),
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
        BlocProvider(create: (_) => ChatMemberBloc()),
        BlocProvider(
            create: (_) => ChatSelectMessageBloc(viewNotifier: viewNotifier)),
      ],
      child: Builder(
        builder: (context) {
          final chatBloc = context.read<ChatBloc>();

          return Provider<ChatController>.value(
            value: chatBloc.chatController,
            child: Column(
              children: [
                // 聊天消息区域 - 使用原有的ChatAnimationListWidget
                Expanded(
                  child: ChatAnimationListWidget(
                    userProfile: userProfile,
                    scrollController: ScrollController(),
                    itemBuilder: (context, animation, message,
                        {bool? isRemoved}) {
                      return TextMessageWidget(
                        message: message as TextMessage,
                        userProfile: userProfile,
                        view: view,
                      );
                    },
                  ),
                ),
                // 输入框区域 - 使用原有的ChatFooter
                ChatFooter(
                  view: view,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
