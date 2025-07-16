import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:get_it/get_it.dart';

class SidebarCalendarButton extends StatelessWidget {
  const SidebarCalendarButton({super.key});

  @override
  Widget build(BuildContext context) {
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
            FlowySvgs.icon_calendar_s,
            size: const Size.square(16.0),
            color: Theme.of(context).iconTheme.color,
          ),
          leftIconSize: const Size.square(16.0),
          iconPadding: 10.0,
          text: FlowyText.medium(
            '日历',
            fontSize: 12,
          ),
          onTap: () {
            GetIt.I<TabsBloc>().add(
              TabsEvent.openPlugin(
                plugin: makePlugin(pluginType: PluginType.calendar),
              ),
            );
          },
        ),
      ),
    );
  }
}
