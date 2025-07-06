import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';

class SidebarAiButton extends StatelessWidget {
  const SidebarAiButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: FlowyHover(
            style: HoverStyle(
              hoverColor: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FlowyButton(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              leftIcon: FlowySvg(
                FlowySvgs.m_home_ai_chat_icon_m,
                size: const Size.square(16.0),
                color: Theme.of(context).iconTheme.color,
              ),
              leftIconSize: const Size.square(16.0),
              iconPadding: 10.0,
              text: FlowyText.medium(
                '问AI',
                fontSize: 12,
              ),
              onTap: () => _openAiChatDialog(context, state),
            ),
          ),
        );
      },
    );
  }

  void _openAiChatDialog(
      BuildContext context, UserWorkspaceState workspaceState) async {
    try {
      // 创建独立的AI聊天插件，不依赖于工作空间
      final standaloneAiChatPlugin = makePlugin(
        pluginType: PluginType.standaloneAiChat,
        data: null, // 独立插件不需要数据
      );

      // 在新标签页中打开独立AI聊天
      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: standaloneAiChatPlugin,
        ),
      );
    } catch (e) {
      _showMessage(context, '打开AI聊天时发生错误: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
