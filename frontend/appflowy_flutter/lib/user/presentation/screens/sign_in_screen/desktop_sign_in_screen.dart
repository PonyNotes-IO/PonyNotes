import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/settings/show_settings.dart';
import 'package:appflowy/shared/window_title_bar.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/screens/qq_qr_login_screen.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/anonymous_sign_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/user/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

class DesktopSignInScreen extends StatefulWidget {
  const DesktopSignInScreen({
    super.key,
  });

  @override
  State<DesktopSignInScreen> createState() => _DesktopSignInScreenState();
}

class _DesktopSignInScreenState extends State<DesktopSignInScreen>
    with WindowListener {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) async {
        final successOrFail = state.successOrFail;
        if (successOrFail != null) {
          if (successOrFail.isSuccess) {
            successOrFail.onSuccess((userProfile) async {
              // 检查是否是QQ登录导航请求
              if (userProfile.email == 'qq_login_navigate') {
                // 导航到QQ二维码登录页面
                _showQQLoginDialog(context);
                return;
              }

              // 匿名登录成功，导航到主页
              getIt<AuthRouter>().goHomeScreen(context, userProfile);
            });
          } else {
            // 显示错误Toast
            successOrFail.onFailure((error) {
              showToastNotification(
                message: error.msg,
                type: ToastificationType.error,
              );
            });
          }
        }
      },
      child: BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) {
          final bottomPadding = UniversalPlatform.isDesktop ? 20.0 : 24.0;
          return Scaffold(
            appBar: _buildAppBar(),
            body: CenteredAuthContainer(
              maxWidth: 380,
              children: [
                // logo and title
                FlowyLogoTitle(
                  title: "欢迎使用小马笔记",
                  logoSize: Size.square(80),
                ),
                VSpace(40),

                // 快速开始按钮
                GestureDetector(
                  onTap: () {
                    // 直接调用匿名登录
                    context
                        .read<SignInBloc>()
                        .add(const SignInEvent.signInAsGuest());
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F0),
                      border: Border.all(color: const Color(0xFFF89575)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      //"LocaleKeys.signIn_quickStart.tr()",
                      "快速开始",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF89575),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                VSpace(10),

                const _OrDivider(),
                VSpace(10),

                // continue with email and password
                isLocalAuthEnabled
                    ? const SignInAnonymousButtonV3()
                    : const ContinueWithEmailAndPassword(),

                VSpace(20),

                // third-party sign in.
                if (isAuthEnabled) ...[
                  const _CustomOrDivider(text: "其他登录方式"),
                  VSpace(40),
                  const ThirdPartySignInButtons(),
                  VSpace(40),
                ],

                // 隐藏设置和匿名登录按钮以符合设计稿
                // const Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     DesktopSignInSettingsButton(),
                //     HSpace(20),
                //     SignInAnonymousButtonV2(),
                //   ],
                // ),
                VSpace(bottomPadding),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(UniversalPlatform.isWindows ? 40 : 60),
      child: UniversalPlatform.isWindows
          ? const WindowTitleBar()
          : const MoveWindowDetector(),
    );
  }

  @override
  void onWindowFocus() {
    // https://pub.dev/packages/window_manager#windows
    // must call setState once when the window is focused
    setState(() {});
  }

  void _showQQLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 480,
              maxHeight: 600,
            ),
            child: QQQRLoginScreen(
              onSuccess: () {
                Navigator.of(context).pop();
                // 这里应该处理QQ登录成功的逻辑
                showToastNotification(
                  message: 'QQ登录成功',
                  type: ToastificationType.success,
                );
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}

class DesktopSignInSettingsButton extends StatelessWidget {
  const DesktopSignInSettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFGhostIconTextButton(
      text: LocaleKeys.signIn_settings.tr(),
      textColor: (context, isHovering, disabled) {
        return theme.textColorScheme.secondary;
      },
      size: AFButtonSize.s,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.xs,
      ),
      onTap: () => showSimpleSettingsDialog(context),
      iconBuilder: (context, isHovering, disabled) {
        return FlowySvg(
          FlowySvgs.settings_s,
          size: Size.square(20),
          color: theme.textColorScheme.secondary,
        );
      },
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: AFDivider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            LocaleKeys.signIn_or.tr(),
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 18,
              fontFamily: 'PingFangSC-Regular',
            ),
          ),
        ),
        Flexible(
          child: AFDivider(),
        ),
      ],
    );
  }
}

class _CustomOrDivider extends StatelessWidget {
  const _CustomOrDivider({required this.text});
  
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 18,
              fontFamily: 'PingFangSC-Regular',
            ),
          ),
        ),
        Flexible(
          child: Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }
}
