import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/settings/show_settings.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarSettingsButton extends StatefulWidget {
  const SidebarSettingsButton({super.key});

  @override
  State<SidebarSettingsButton> createState() => _SidebarSettingsButtonState();
}

class _SidebarSettingsButtonState extends State<SidebarSettingsButton> {
  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AFGhostIconTextButton.primary(
        text: '设置',
        mainAxisAlignment: MainAxisAlignment.start,
        size: AFButtonSize.l,
        onTap: () => showNewSettingsDialog(context),
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        borderRadius: theme.borderRadius.s,
        iconBuilder: (context, isHover, disabled) => FlowySvg(
          FlowySvgs.icon_settings_s,
          size: const Size.square(16.0),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
