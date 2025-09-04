import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarInboxButton extends StatelessWidget {
  const SidebarInboxButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AFGhostIconTextButton.primary(
        text: '收件箱',
        mainAxisAlignment: MainAxisAlignment.start,
        size: AFButtonSize.l,
        onTap: () => _openInboxPage(context),
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        borderRadius: theme.borderRadius.s,
        iconBuilder: (context, isHover, disabled) => FlowySvg(
          FlowySvgs.icon_inbox_s,
          size: const Size.square(16.0),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  void _openInboxPage(BuildContext context) async {
    try {
      // 创建收件箱插件
      final inboxPlugin = makePlugin(
        pluginType: PluginType.inbox,
        data: null,
      );

      // 在新标签页中打开收件箱
      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: inboxPlugin,
        ),
      );
    } catch (e) {
      debugPrint('打开收件箱时发生错误: $e');
    }
  }
}
