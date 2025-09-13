import 'dart:async';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings_cubit.freezed.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit() : super(NotificationSettingsState.initial()) {
    _initialize();
  }

  final Completer<void> _initCompleter = Completer();

  late final NotificationSettingsPB _notificationSettings;

  Future<void> _initialize() async {
    _notificationSettings =
        await UserSettingsBackendService().getNotificationSettings();

    final showNotificationSetting = await getIt<KeyValueStorage>()
        .getWithFormat(KVKeys.showNotificationIcon, (v) => bool.parse(v));
    
    // Load individual notification type settings
    final mentionNotifications = await getIt<KeyValueStorage>()
        .getWithFormat('mention_notifications', (v) => bool.parse(v));
    final pendingNotifications = await getIt<KeyValueStorage>()
        .getWithFormat('pending_notifications', (v) => bool.parse(v));
    final permissionChangeNotifications = await getIt<KeyValueStorage>()
        .getWithFormat('permission_change_notifications', (v) => bool.parse(v));
    final teamJoinNotifications = await getIt<KeyValueStorage>()
        .getWithFormat('team_join_notifications', (v) => bool.parse(v));
    final clipNotifications = await getIt<KeyValueStorage>()
        .getWithFormat('clip_notifications', (v) => bool.parse(v));

    emit(
      state.copyWith(
        isNotificationsEnabled: _notificationSettings.notificationsEnabled,
        isShowNotificationsIconEnabled: showNotificationSetting ?? true,
        isMentionNotificationsEnabled: mentionNotifications ?? true,
        isPendingNotificationsEnabled: pendingNotifications ?? true,
        isPermissionChangeNotificationsEnabled: permissionChangeNotifications ?? true,
        isTeamJoinNotificationsEnabled: teamJoinNotifications ?? true,
        isClipNotificationsEnabled: clipNotifications ?? true,
      ),
    );

    _initCompleter.complete();
  }

  Future<void> toggleNotificationsEnabled() async {
    await _initCompleter.future;

    _notificationSettings.notificationsEnabled = !state.isNotificationsEnabled;

    emit(
      state.copyWith(
        isNotificationsEnabled: _notificationSettings.notificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> toggleShowNotificationIconEnabled() async {
    await _initCompleter.future;

    emit(
      state.copyWith(
        isShowNotificationsIconEnabled: !state.isShowNotificationsIconEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> toggleMentionNotificationsEnabled() async {
    await _initCompleter.future;

    emit(
      state.copyWith(
        isMentionNotificationsEnabled: !state.isMentionNotificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> togglePendingNotificationsEnabled() async {
    await _initCompleter.future;

    emit(
      state.copyWith(
        isPendingNotificationsEnabled: !state.isPendingNotificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> togglePermissionChangeNotificationsEnabled() async {
    await _initCompleter.future;

    emit(
      state.copyWith(
        isPermissionChangeNotificationsEnabled: !state.isPermissionChangeNotificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> toggleTeamJoinNotificationsEnabled() async {
    await _initCompleter.future;

    emit(
      state.copyWith(
        isTeamJoinNotificationsEnabled: !state.isTeamJoinNotificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> toggleClipNotificationsEnabled() async {
    await _initCompleter.future;

    emit(
      state.copyWith(
        isClipNotificationsEnabled: !state.isClipNotificationsEnabled,
      ),
    );

    await _saveNotificationSettings();
  }

  Future<void> _saveNotificationSettings() async {
    await _initCompleter.future;

    await getIt<KeyValueStorage>().set(
      KVKeys.showNotificationIcon,
      state.isShowNotificationsIconEnabled.toString(),
    );

    // Save individual notification type settings
    await getIt<KeyValueStorage>().set(
      'mention_notifications',
      state.isMentionNotificationsEnabled.toString(),
    );
    await getIt<KeyValueStorage>().set(
      'pending_notifications',
      state.isPendingNotificationsEnabled.toString(),
    );
    await getIt<KeyValueStorage>().set(
      'permission_change_notifications',
      state.isPermissionChangeNotificationsEnabled.toString(),
    );
    await getIt<KeyValueStorage>().set(
      'team_join_notifications',
      state.isTeamJoinNotificationsEnabled.toString(),
    );
    await getIt<KeyValueStorage>().set(
      'clip_notifications',
      state.isClipNotificationsEnabled.toString(),
    );

    final result = await UserSettingsBackendService()
        .setNotificationSettings(_notificationSettings);
    result.fold(
      (r) => null,
      (error) => Log.error(error),
    );
  }
}

@freezed
class NotificationSettingsState with _$NotificationSettingsState {
  const NotificationSettingsState._();

  const factory NotificationSettingsState({
    required bool isNotificationsEnabled,
    required bool isShowNotificationsIconEnabled,
    required bool isMentionNotificationsEnabled,
    required bool isPendingNotificationsEnabled,
    required bool isPermissionChangeNotificationsEnabled,
    required bool isTeamJoinNotificationsEnabled,
    required bool isClipNotificationsEnabled,
  }) = _NotificationSettingsState;

  factory NotificationSettingsState.initial() =>
      const NotificationSettingsState(
        isNotificationsEnabled: true,
        isShowNotificationsIconEnabled: true,
        isMentionNotificationsEnabled: true,
        isPendingNotificationsEnabled: true,
        isPermissionChangeNotificationsEnabled: true,
        isTeamJoinNotificationsEnabled: true,
        isClipNotificationsEnabled: true,
      );
}
