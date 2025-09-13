import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_list_tile.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsNotificationsView extends StatelessWidget {
  const SettingsNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        return SettingsBody(
          title: LocaleKeys.settings_menu_notifications.tr(),
          children: [
            SettingListTile(
              label: LocaleKeys.settings_notifications_mentionNotifications_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_mentionNotifications_hint
                  .tr(),
              trailing: [
                Toggle(
                  value: state.isMentionNotificationsEnabled,
                  onChanged: (_) => context
                      .read<NotificationSettingsCubit>()
                      .toggleMentionNotificationsEnabled(),
                ),
              ],
            ),
            SettingListTile(
              label: LocaleKeys.settings_notifications_pendingNotifications_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_pendingNotifications_hint
                  .tr(),
              trailing: [
                Toggle(
                  value: state.isPendingNotificationsEnabled,
                  onChanged: (_) => context
                      .read<NotificationSettingsCubit>()
                      .togglePendingNotificationsEnabled(),
                ),
              ],
            ),
            SettingListTile(
              label: LocaleKeys.settings_notifications_permissionChangeNotifications_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_permissionChangeNotifications_hint
                  .tr(),
              trailing: [
                Toggle(
                  value: state.isPermissionChangeNotificationsEnabled,
                  onChanged: (_) => context
                      .read<NotificationSettingsCubit>()
                      .togglePermissionChangeNotificationsEnabled(),
                ),
              ],
            ),
            SettingListTile(
              label: LocaleKeys.settings_notifications_teamJoinNotifications_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_teamJoinNotifications_hint
                  .tr(),
              trailing: [
                Toggle(
                  value: state.isTeamJoinNotificationsEnabled,
                  onChanged: (_) => context
                      .read<NotificationSettingsCubit>()
                      .toggleTeamJoinNotificationsEnabled(),
                ),
              ],
            ),
            SettingListTile(
              label: LocaleKeys.settings_notifications_clipNotifications_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_clipNotifications_hint
                  .tr(),
              trailing: [
                Toggle(
                  value: state.isClipNotificationsEnabled,
                  onChanged: (_) => context
                      .read<NotificationSettingsCubit>()
                      .toggleClipNotificationsEnabled(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
