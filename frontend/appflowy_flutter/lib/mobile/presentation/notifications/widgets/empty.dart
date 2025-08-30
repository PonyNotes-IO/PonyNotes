import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_tab_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class EmptyNotification extends StatelessWidget {
  const EmptyNotification({
    super.key,
    required this.type,
  });

  final NotificationTabType type;

  @override
  Widget build(BuildContext context) {
    final title = switch (type) {
      NotificationTabType.mention =>
        "暂无@提及通知",
      NotificationTabType.clip =>
        "暂无剪藏通知",
      NotificationTabType.reminder =>
        "暂无提醒通知",
      NotificationTabType.system =>
        "暂无系统通知",
    };
    final desc = switch (type) {
      NotificationTabType.mention =>
        "当有人@提及您时，通知将显示在此处。",
      NotificationTabType.clip =>
        "当您剪藏内容时，通知将显示在此处。",
      NotificationTabType.reminder =>
        "当您设置提醒时，通知将显示在此处。",
      NotificationTabType.system =>
        "系统相关的通知将显示在此处。",
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FlowySvg(FlowySvgs.m_empty_notification_xl),
        const VSpace(12.0),
        FlowyText(
          title,
          fontSize: 16.0,
          figmaLineHeight: 24.0,
          fontWeight: FontWeight.w500,
        ),
        const VSpace(4.0),
        Opacity(
          opacity: 0.45,
          child: FlowyText(
            desc,
            fontSize: 15.0,
            figmaLineHeight: 22.0,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
