import 'package:appflowy/plugins/ai_chat/presentation/chat_message_selector_banner.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_animation_list_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_footer.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_message_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/text_message_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/scroll_to_bottom.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatMessage;
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class LoadChatMessageStatusReady extends StatelessWidget {
  const LoadChatMessageStatusReady({
    super.key,
    required this.view,
    required this.userProfile,
    required this.chatController,
  });

  final ViewPB view;
  final UserProfilePB userProfile;
  final ChatController chatController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat navigation bar with back button
        _buildNavigationBar(context),
        // Chat header, banner
        _buildHeader(context),
        // Chat body, a list of messages
        _buildBody(context),
        // Chat footer, a text input field with toolbar, send button, etc.
        _buildFooter(context),
      ],
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _navigateToHomePage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlowySvg(
                      FlowySvgs.arrow_left_s,
                      size: const Size.square(20),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const HSpace(8),
                    FlowyText.medium(
                      'AI 助手',
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ChatMessageSelectorBanner(
      view: view,
      allMessages: chatController.messages,
    );
  }

  Widget _buildBody(BuildContext context) {
    final bool enableAnimation = true;
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: _wrapConstraints(
          SelectionArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: Provider<ChatController>.value(
                value: chatController,
                child: Chat(
                  chatController: chatController,
                  user: User(id: userProfile.id.toString()),
                  darkTheme: ChatTheme.fromThemeData(Theme.of(context)),
                  theme: ChatTheme.fromThemeData(Theme.of(context)),
                  builders: Builders(
                    // we have a custom input builder, so we don't need the default one
                    inputBuilder: (_) => const SizedBox.shrink(),
                    textMessageBuilder: (
                      context,
                      message,
                    ) =>
                        TextMessageWidget(
                      message: message,
                      userProfile: userProfile,
                      view: view,
                      enableAnimation: enableAnimation,
                    ),
                    chatMessageBuilder: (
                      context,
                      message,
                      animation,
                      child,
                    ) =>
                        ChatMessage(
                      message: message,
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: child,
                    ),
                    scrollToBottomBuilder: (
                      context,
                      animation,
                      onPressed,
                    ) =>
                        CustomScrollToBottom(
                      animation: animation,
                      onPressed: onPressed,
                    ),
                    chatAnimatedListBuilder: (
                      context,
                      scrollController,
                      itemBuilder,
                    ) =>
                        ChatAnimationListWidget(
                      userProfile: userProfile,
                      scrollController: scrollController,
                      itemBuilder: itemBuilder,
                      enableReversedList: !enableAnimation,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return _wrapConstraints(
      ChatFooter(view: view),
    );
  }

  Widget _wrapConstraints(Widget child) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 784),
      margin: UniversalPlatform.isDesktop
          ? const EdgeInsets.symmetric(horizontal: 60.0)
          : null,
      child: child,
    );
  }

  void _navigateToHomePage() {
    try {
      // 创建主页插件
      final homePlugin = makePlugin(
        pluginType: PluginType.homepage,
        data: null,
      );

      // 在新标签页中打开主页
      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: homePlugin,
        ),
      );
    } catch (e) {
      // 如果出现错误，可以显示提示信息
      debugPrint('打开主页时发生错误: $e');
    }
  }
}
