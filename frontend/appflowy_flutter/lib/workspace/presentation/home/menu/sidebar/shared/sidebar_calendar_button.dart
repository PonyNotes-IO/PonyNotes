import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarCalendarButton extends StatelessWidget {
  const SidebarCalendarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AFGhostIconTextButton.primary(
            text: '日历',
            mainAxisAlignment: MainAxisAlignment.start,
            size: AFButtonSize.l,
            onTap: () => _openCalendar(context, state),
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            borderRadius: theme.borderRadius.s,
            iconBuilder: (context, isHover, disabled) => FlowySvg(
              FlowySvgs.icon_calendar_s,
              size: const Size.square(16.0),
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        );
      },
    );
  }

  void _openCalendar(
      BuildContext context, UserWorkspaceState workspaceState) async {
    try {
      // 创建日历插件
      final calendarPlugin = makePlugin(
        pluginType: PluginType.calendar,
        data: null,
      );

      // 在新标签页中打开日历
      context.read<TabsBloc>().add(
        TabsEvent.openPlugin(plugin: calendarPlugin),
      );
    } catch (e) {
      // 静默处理错误，不显示用户
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
