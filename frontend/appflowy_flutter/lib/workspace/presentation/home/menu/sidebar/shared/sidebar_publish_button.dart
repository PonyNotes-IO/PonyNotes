import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarPublishButton extends StatelessWidget {
  const SidebarPublishButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AFGhostIconTextButton.primary(
        text: '发布',
        mainAxisAlignment: MainAxisAlignment.start,
        size: AFButtonSize.l,
        onTap: () {
          // 测试代码，打印日志
          debugPrint('发布按钮被点击了');
        },
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        borderRadius: theme.borderRadius.s,
        iconBuilder: (context, isHover, disabled) => FlowySvg(
          FlowySvgs.icon_folder_s,
          size: const Size.square(16.0),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
