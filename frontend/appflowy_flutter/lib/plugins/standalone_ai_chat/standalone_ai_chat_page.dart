import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_member_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_animation_list_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_footer.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/text_message_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_message_widget.dart' as app_flowy;
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:appflowy/plugins/ai_chat/presentation/scroll_to_bottom.dart';
import 'package:provider/provider.dart';
import 'package:flowy_infra/uuid.dart';
import 'presentation/ai_welcome_page.dart';

class StandaloneAiChatPage extends StatefulWidget {
  const StandaloneAiChatPage({
    super.key,
    required this.userProfile,
    this.initialText,
    this.selectedModel,
  });

  final UserProfilePB userProfile;
  final String? initialText;
  final AIModelPB? selectedModel;

  @override
  State<StandaloneAiChatPage> createState() => _StandaloneAiChatPageState();
}

class _StandaloneAiChatPageState extends State<StandaloneAiChatPage> {
  late final String chatId;
  late final ViewPB view;
  late final ViewPluginNotifier viewNotifier;
  bool _isInitialized = false;
  bool _showWelcomePage = true; // 控制是否显示欢迎页面

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// 专为独立AI聊天界面设计的初始化逻辑
  Future<void> _initializeChat() async {
    // 使用UUID格式的聊天ID，确保兼容后端UUID解析
    chatId = uuid();

    // 创建一个真实的ViewPB用于聊天，不是虚拟的
    view = ViewPB()
      ..id = chatId
      ..name = 'AI聊天'
      ..layout = ViewLayoutPB.Chat;

    // 创建ViewPluginNotifier
    viewNotifier = ViewPluginNotifier(view: view);

    // 预创建聊天记录以避免外键约束错误
    await _ensureStandaloneChatExists();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        // 如果有初始文本，直接切换到聊天界面
        _showWelcomePage = widget.initialText == null || widget.initialText!.isEmpty;
      });
      
      // 如果有选中的模型，先设置模型
      if (widget.selectedModel != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setSelectedModel();
        });
      }
      
      // 如果有初始文本，在初始化完成后发送
      if (widget.initialText != null && widget.initialText!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendInitialMessage();
        });
      }
    }
  }

  /// 确保独立AI聊天记录存在（仅用于StandaloneAiChatPage）
  Future<void> _ensureStandaloneChatExists() async {
    // 由于独立AI聊天是临时的，我们不需要预先创建数据库记录
    // 聊天记录会在第一条消息发送时自动创建
    // 这样可以避免不必要的数据库操作和潜在的错误
  }

  /// 设置选中的模型
  void _setSelectedModel() {
    if (!mounted || widget.selectedModel == null) {
      return;
    }

    try {
      AIEventUpdateSelectedModel(
        UpdateSelectedModelPB(
          source: chatId, // 使用chatId作为source
          selectedModel: widget.selectedModel!,
        ),
      ).send();
    } catch (e) {
      debugPrint('设置选中模型失败: $e');
    }
  }

  /// 发送初始消息
  void _sendInitialMessage() {
    if (!mounted || widget.initialText == null || widget.initialText!.isEmpty) {
      return;
    }

    try {
      final chatBloc = context.read<ChatBloc>();
      chatBloc.add(ChatEvent.sendMessage(
        message: widget.initialText!,
      ));
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('发送初始消息时出错: $e');
    }
  }

  /// 从欢迎页面切换到聊天界面
  void _switchToChatPage() {
    setState(() {
      _showWelcomePage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(
            chatId: chatId,
            userId: widget.userProfile.id.toString(),
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

          // 根据状态显示欢迎页面或聊天页面
          if (_showWelcomePage) {
            return AIWelcomePage(
              onMessageSent: _switchToChatPage,
            );
          }

          return Provider<ChatController>.value(
            value: chatBloc.chatController,
            child: Provider<User>.value(
              value: User(id: widget.userProfile.id.toString()),
              child: Provider<Builders>(
              create: (_) => Builders(
                // we have a custom input builder, so we don't need the default one
                inputBuilder: (_) => const SizedBox.shrink(),
                textMessageBuilder: (context, message) => TextMessageWidget(
                  message: message,
                  userProfile: widget.userProfile,
                  view: view,
                ),
                chatMessageBuilder: (context, message, animation, child) =>
                    app_flowy.ChatMessage(
                  message: message,
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: child,
                ),
                scrollToBottomBuilder: (context, animation, onPressed) =>
                    CustomScrollToBottom(
                  animation: animation,
                  onPressed: onPressed,
                ),
              ),
              child: Column(
                children: [
                  // 聊天消息区域 - 使用原有的ChatAnimationListWidget
                  Expanded(
                    child: ChatAnimationListWidget(
                      userProfile: widget.userProfile,
                      scrollController: ScrollController(),
                      itemBuilder: (context, animation, message,
                          {bool? isRemoved}) {
                        return TextMessageWidget(
                          message: message as TextMessage,
                          userProfile: widget.userProfile,
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
            ),
          ),
        );
        },
      ),
    );
  }
}
