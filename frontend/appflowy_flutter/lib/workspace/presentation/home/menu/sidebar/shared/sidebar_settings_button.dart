import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/password/password_bloc.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/home/af_focus_manager.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

final GlobalKey _settingsDialogKey = GlobalKey();

class SidebarSettingsButton extends StatefulWidget {
  const SidebarSettingsButton({super.key});

  @override
  State<SidebarSettingsButton> createState() => _SidebarSettingsButtonState();
}

class _SidebarSettingsButtonState extends State<SidebarSettingsButton> {
  late UserWorkspaceBloc _userWorkspaceBloc;
  late PasswordBloc _passwordBloc;

  @override
  void initState() {
    super.initState();

    _userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    _passwordBloc = PasswordBloc(_userWorkspaceBloc.state.userProfile)
      ..add(PasswordEvent.init())
      ..add(PasswordEvent.checkHasPassword());
  }

  @override
  void didChangeDependencies() {
    _userWorkspaceBloc = context.read<UserWorkspaceBloc>();

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _passwordBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AFGhostIconTextButton.primary(
            text: '设置',
            mainAxisAlignment: MainAxisAlignment.start,
            size: AFButtonSize.l,
            onTap: () => showSettingsDialog(
              context,
              userWorkspaceBloc: _userWorkspaceBloc,
              passwordBloc: _passwordBloc,
            ),
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
      },
    );
  }
}

void showSettingsDialog(
  BuildContext context, {
  required UserWorkspaceBloc userWorkspaceBloc,
  PasswordBloc? passwordBloc,
  SettingsPage? initPage,
}) {
  final userProfile = context.read<UserWorkspaceBloc>().state.userProfile;
  AFFocusManager.maybeOf(context)?.notifyLoseFocus();
  showDialog(
    context: context,
    builder: (dialogContext) => MultiBlocProvider(
      key: _settingsDialogKey,
      providers: [
        passwordBloc != null
            ? BlocProvider<PasswordBloc>.value(
                value: passwordBloc,
              )
            : BlocProvider(
                create: (context) => PasswordBloc(userProfile)
                  ..add(PasswordEvent.init())
                  ..add(PasswordEvent.checkHasPassword()),
              ),
        BlocProvider<DocumentAppearanceCubit>.value(
          value: BlocProvider.of<DocumentAppearanceCubit>(dialogContext),
        ),
        BlocProvider.value(
          value: userWorkspaceBloc,
        ),
      ],
      child: SettingsDialog(
        userProfile,
        initPage: initPage,
        didLogout: () async {
          // Pop the dialog using the dialog context
          Navigator.of(dialogContext).pop();
          await runAppFlowy();
        },
        dismissDialog: () {
          if (Navigator.of(dialogContext).canPop()) {
            return Navigator.of(dialogContext).pop();
          }
          Log.warn("Can't pop dialog context");
        },
        restartApp: () async {
          // Pop the dialog using the dialog context
          Navigator.of(dialogContext).pop();
          await runAppFlowy();
        },
      ),
    ),
  );
}
