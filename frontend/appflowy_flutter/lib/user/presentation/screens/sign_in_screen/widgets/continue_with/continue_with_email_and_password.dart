import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_magic_link_or_passcode_page.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_password.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_password_page.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';
import 'package:appflowy/util/validator.dart';

class ContinueWithEmailAndPassword extends StatefulWidget {
  const ContinueWithEmailAndPassword({super.key});

  @override
  State<ContinueWithEmailAndPassword> createState() =>
      _ContinueWithEmailAndPasswordState();
}

class _ContinueWithEmailAndPasswordState
    extends State<ContinueWithEmailAndPassword> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  final emailKey = GlobalKey<AFTextFieldState>();

  bool _hasPushedContinueWithMagicLinkOrPasscodePage = false;
  bool _agreed = false;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.successOrFail;
        // only push the continue with magic link or passcode page if the magic link is sent successfully
        if (successOrFail != null) {
          successOrFail.fold(
            (_) => emailKey.currentState?.clearError(),
            (error) => emailKey.currentState?.syncError(
              errorText: error.msg,
            ),
          );
        } else if (successOrFail == null && !state.isSubmitting) {
          emailKey.currentState?.clearError();
        }
      },
      child: Column(
        children: [
          AFTextField(
            key: emailKey,
            controller: controller,
            hintText: LocaleKeys.signIn_pleaseInputYourEmailOrMobile.tr(),
            onSubmitted: (value) => _signInWithEmail(
              context,
              value,
            ),
          ),
          VSpace(theme.spacing.l),
          /*
          ContinueWithEmail(
            onTap: () => _signInWithEmail(
              context,
              controller.text,
            ),
          ),
          */
          VSpace(theme.spacing.l),
          AFFilledTextButton.primary(
            text: LocaleKeys.signIn_loginOrRegister.tr(),
            size: AFButtonSize.l,
            alignment: Alignment.center,
            onTap: () {
              // 这里可以添加实际的登录/注册逻辑，当前先打印日志
              debugPrint('点击了登录/注册按钮');
            },
          ),
          VSpace(theme.spacing.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _agreed,
                onChanged: (value) {
                  setState(() {
                    _agreed = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(LocaleKeys.signIn_agreePrefix.tr()),
                    GestureDetector(
                      onTap: () {
                        // TODO: 跳转到用户协议页面
                        debugPrint('点击了用户协议');
                      },
                      child: Text(
                        LocaleKeys.signIn_userAgreement.tr(),
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                    Text(LocaleKeys.signIn_and.tr()),
                    GestureDetector(
                      onTap: () {
                        // TODO: 跳转到隐私政策页面
                        debugPrint('点击了隐私政策');
                      },
                      child: Text(
                        LocaleKeys.signIn_privacyPolicy.tr(),
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          VSpace(theme.spacing.l),
          /*
          ContinueWithPassword(
            onTap: () {
              final email = controller.text;

              if (!_isValidEmailOrPhone(email)) {
                emailKey.currentState?.syncError(
                  errorText: LocaleKeys.signIn_invalidEmail.tr(),
                );
                return;
              }

              _pushContinueWithPasswordPage(
                context,
                email,
              );
            },
          ),
          */
        ],
      ),
    );
  }

  void _signInWithEmail(BuildContext context, String input) {
    if (!Validator.isValidEmailOrPhone(input)) {
      String errorText;
      if (input.contains('@')) {
        errorText = '请输入有效的邮箱地址';
      } else {
        errorText = '请输入有效的手机号';
      }
      emailKey.currentState?.syncError(
        errorText: errorText,
      );
      return;
    }
    context
        .read<SignInBloc>()
        .add(SignInEvent.signInWithMagicLink(email: input));
    _pushContinueWithMagicLinkOrPasscodePage(
      context,
      input,
    );
  }

  void _pushContinueWithMagicLinkOrPasscodePage(
    BuildContext context,
    String email,
  ) {
    if (_hasPushedContinueWithMagicLinkOrPasscodePage) {
      return;
    }

    final signInBloc = context.read<SignInBloc>();

    // push the a continue with magic link or passcode screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: signInBloc,
          child: ContinueWithMagicLinkOrPasscodePage(
            email: email,
            backToLogin: () {
              Navigator.pop(context);

              emailKey.currentState?.clearError();

              _hasPushedContinueWithMagicLinkOrPasscodePage = false;
            },
            onEnterPasscode: (passcode) {
              signInBloc.add(
                SignInEvent.signInWithPasscode(
                  email: email,
                  passcode: passcode,
                ),
              );
            },
          ),
        ),
      ),
    );

    _hasPushedContinueWithMagicLinkOrPasscodePage = true;
  }

  void _pushContinueWithPasswordPage(
    BuildContext context,
    String email,
  ) {
    final signInBloc = context.read<SignInBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/continue-with-password'),
        builder: (context) => BlocProvider.value(
          value: signInBloc,
          child: ContinueWithPasswordPage(
            email: email,
            backToLogin: () {
              emailKey.currentState?.clearError();
              Navigator.pop(context);
            },
            onEnterPassword: (password) => signInBloc.add(
              SignInEvent.signInWithEmailAndPassword(
                email: email,
                password: password,
              ),
            ),
            onForgotPassword: () {
              // todo: implement forgot password
            },
          ),
        ),
      ),
    );
  }
}
