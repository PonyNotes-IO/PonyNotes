import 'dart:async';

import 'package:appflowy/features/settings/settings.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:appflowy/shared/appflowy_cache_manager.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsStorageView extends StatelessWidget {
  const SettingsStorageView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DataLocationBloc>(
      create: (_) => DataLocationBloc(
        repository: const RustSettingsRepositoryImpl(),
      )..add(DataLocationEvent.initial()),
      child: BlocConsumer<DataLocationBloc, DataLocationState>(
        listenWhen: (previous, current) =>
            previous.didResetToDefault != current.didResetToDefault,
        listener: (context, state) {
          if (state.didResetToDefault) {
            Navigator.of(context).pop();
            runAppFlowy(isAnon: true);
          }
        },
        builder: (context, state) {
          final path = state.userDataLocation?.path;

          return SettingsBody(
            title: '存储设置',
            description: '管理您的数据存储和缓存设置',
            children: [
              // 本地默认存储路径设置
              SettingsCategory(
                title: '本地默认存储路径',
                tooltip: '设置本地数据的存储位置',
                children: path == null
                    ? [
                        const CircularProgressIndicator(),
                      ]
                    : [
                        _LocalStoragePath(path: path),
                      ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocalStoragePath extends StatelessWidget {
  const _LocalStoragePath({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FlowyTooltip(
                message: '点击打开文件夹',
                child: GestureDetector(
                  onTap: () => {
                    afLaunchUri(Uri.file(path)),
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      path,
                      maxLines: 2,
                      style: theme.textStyle.body
                          .standard(color: theme.textColorScheme.action)
                          .copyWith(
                            decoration: TextDecoration.underline,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            HSpace(
              theme.spacing.m,
            ),
            FlowyTooltip(
              message: '修改存储路径',
              child: AFGhostButton.normal(
                builder: (context, _, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowySvg(
                        FlowySvgs.edit_s,
                        size: Size.square(20),
                        color: theme.textColorScheme.primary,
                      ),
                      HSpace(theme.spacing.s),
                      Text(
                        '修改',
                        style: theme.textStyle.body.standard(
                          color: theme.textColorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
                padding: EdgeInsets.all(theme.spacing.m),
                onTap: () async {
                  final newPath =
                      await getIt<FilePickerService>().getDirectoryPath();
                  if (newPath == null || newPath == path) {
                    return;
                  }

                  // 显示确认对话框
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认修改存储路径'),
                      content:
                          Text('您确定要将存储路径修改为：\n$newPath\n\n这将会移动您的数据到新位置。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('确认'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    context
                        .read<DataLocationBloc>()
                        .add(DataLocationEvent.setCustomPath(newPath));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
