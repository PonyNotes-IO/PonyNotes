import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarAiButton extends StatelessWidget {
  const SidebarAiButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AFGhostIconTextButton.primary(
            text: '问AI',
            mainAxisAlignment: MainAxisAlignment.start,
            size: AFButtonSize.l,
            onTap: () => _openAiChatDialog(context, state),
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            borderRadius: theme.borderRadius.s,
            iconBuilder: (context, isHover, disabled) => FlowySvg(
              FlowySvgs.icon_ai_s,
              size: const Size.square(16.0),
              color: Theme.of(context).textTheme.bodyMedium?.color,
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
