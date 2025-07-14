import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/back_to_login_in_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/forgot_password_page.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/verifying_button.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/password/password_suffix_icon.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinueWithPasswordPage extends StatefulWidget {
  const ContinueWithPasswordPage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.onEnterPassword,
    required this.onForgotPassword,
  });

  final String email;
  final VoidCallback backToLogin;
  final ValueChanged<String> onEnterPassword;
  final VoidCallback onForgotPassword;

  @override
  State<ContinueWithPasswordPage> createState() =>
      _ContinueWithPasswordPageState();
}

class _ContinueWithPasswordPageState extends State<ContinueWithPasswordPage> {
  final passwordController = TextEditingController();
  final inputPasswordKey = GlobalKey<AFTextFieldState>();

  bool isSubmitting = false;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: BlocListener<SignInBloc, SignInState>(
            listener: (context, state) {
              // 不再展示任何密码输入错误提示
              inputPasswordKey.currentState?.clearError();

              if (isSubmitting != state.isSubmitting) {
                setState(() {
                  isSubmitting = state.isSubmitting;
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                // 头像
                const Icon(Icons.account_box_rounded,
                    size: 64, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                // 邮箱
                Text(
                  widget.email,
                  style: theme.textStyle.body.enhanced(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 输入密码标题
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      LocaleKeys.signIn_inputPasswordTitle.tr(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                // 密码输入框
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AFTextField(
                          key: inputPasswordKey,
                          controller: passwordController,
                          hintText: LocaleKeys.signIn_inputPasswordHint.tr(),
                          autoFocus: true,
                          obscureText: true,
                          onSubmitted: widget.onEnterPassword,
                        ),
                      ),
                    ],
                  ),
                ),
                // 忘记密码/重置密码
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 2),
                  child: Row(
                    children: [
                      Expanded(child: Container()),
                      Builder(
                        builder: (context) {
                          final theme = AppFlowyTheme.of(context);
                          return Text(
                            LocaleKeys.signIn_forgotPasswordText.tr(),
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.textColorScheme.primary),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () async {
                          final signInBloc = context.read<SignInBloc>();
                          final baseUrl = await getAppFlowyCloudUrl();
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: signInBloc,
                                child: ForgotPasswordPage(
                                  email: widget.email,
                                  backToLogin: widget.backToLogin,
                                  baseUrl: baseUrl,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Builder(
                          builder: (context) {
                            final theme = AppFlowyTheme.of(context);
                            return Text(
                              LocaleKeys.signIn_resetPasswordText.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textColorScheme.action,
                                decoration: TextDecoration.underline,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 确认按钮
                ContinueWithButton(
                  text: LocaleKeys.signIn_submitButton.tr(),
                  onTap: isSubmitting
                      ? () {}
                      : () => widget.onEnterPassword(passwordController.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoAndTitle() {
    final theme = AppFlowyTheme.of(context);
    return TitleLogo(
      title: LocaleKeys.signIn_enterPassword.tr(),
      informationBuilder: (context) => // email display
          RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: LocaleKeys.signIn_loginAs.tr(),
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
            TextSpan(
              text: ' ${widget.email}',
              style: theme.textStyle.body.enhanced(
                color: theme.textColorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPasswordSection() {
    final theme = AppFlowyTheme.of(context);
    final iconSize = 20.0;

    return [
      // Password input
      AFTextField(
        key: inputPasswordKey,
        controller: passwordController,
        hintText: LocaleKeys.signIn_enterPassword.tr(),
        autoFocus: true,
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => PasswordSuffixIcon(
          isObscured: isObscured,
          onTap: () {
            inputPasswordKey.currentState?.syncObscured(!isObscured);
          },
        ),
        onSubmitted: widget.onEnterPassword,
      ),
      // todo: ask designer to provide the spacing
      VSpace(8),

      // Forgot password button
      Align(
        alignment: Alignment.centerLeft,
        child: AFGhostTextButton(
          text: LocaleKeys.signIn_forgotPassword.tr(),
          size: AFButtonSize.s,
          padding: EdgeInsets.zero,
          onTap: () => _pushForgotPasswordPage(),
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.action,
          ),
          textColor: (context, isHovering, disabled) {
            final theme = AppFlowyTheme.of(context);
            if (isHovering) {
              return theme.textColorScheme.actionHover;
            }
            return theme.textColorScheme.action;
          },
        ),
      ),
      VSpace(theme.spacing.xxl),

      // Continue button
      isSubmitting
          ? const VerifyingButton()
          : ContinueWithButton(
              text: LocaleKeys.web_continue.tr(),
              onTap: () => widget.onEnterPassword(passwordController.text),
            ),
      VSpace(20),
    ];
  }

  Future<void> _pushForgotPasswordPage() async {
    final signInBloc = context.read<SignInBloc>();
    final baseUrl = await getAppFlowyCloudUrl();

    if (mounted && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/forgot-password'),
          builder: (context) => BlocProvider.value(
            value: signInBloc,
            child: ForgotPasswordPage(
              email: widget.email,
              backToLogin: widget.backToLogin,
              baseUrl: baseUrl,
            ),
          ),
        ),
      );
    }
  }
}
