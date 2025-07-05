import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/plugins/ai_chat/chat.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
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
      // 获取当前工作空间
      final currentWorkspace = workspaceState.currentWorkspace;
      if (currentWorkspace == null) {
        _showMessage(context, '无法获取当前工作空间');
        return;
      }

      // 创建AI聊天视图
      final result = await ViewBackendService.createView(
        parentViewId: currentWorkspace.workspaceId,
        name: LocaleKeys.chat_newChat.tr(),
        layoutType: ViewLayoutPB.Chat,
        openAfterCreate: false,
      );

      result.fold(
        (view) {
          // 创建AI聊天插件
          final aiChatPlugin = makePlugin(
            pluginType: PluginType.chat,
            data: view,
          );

          // 在新标签页中打开AI聊天
          getIt<TabsBloc>().add(
            TabsEvent.openPlugin(
              plugin: aiChatPlugin,
            ),
          );
        },
        (error) {
          _showMessage(context, '创建AI聊天失败: ${error.msg}');
        },
      );
    } catch (e) {
      _showMessage(context, '创建AI聊天时发生错误: $e');
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
