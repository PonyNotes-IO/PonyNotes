import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_magic_link_or_passcode_page.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_password.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_password_page.dart';
import 'package:appflowy/user/presentation/utils/legal_document_navigator.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
              final emailOrPhone = controller.text.trim();
              if (!Validator.isValidEmailOrPhone(emailOrPhone)) {
                emailKey.currentState?.syncError(
                  errorText: LocaleKeys.signIn_invalidEmailOrPhone.tr(),
                );
                return;
              }
              if (!_agreed) {
                final parentContext = context;
                showDialog(
                  context: parentContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(LocaleKeys.signIn_betterUseService.tr()),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LocaleKeys.signIn_pleaseReadAndAgreeBeforeLogin
                            .tr()),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(LocaleKeys.appName.tr()),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                LegalDocumentNavigator.navigateToUserAgreement(
                                    parentContext);
                              },
                              child: Text(
                                LocaleKeys.signIn_userAgreement.tr(),
                                style: TextStyle(
                                  color: AppFlowyTheme.of(parentContext)
                                      .textColorScheme
                                      .action,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text('、'),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                LegalDocumentNavigator.navigateToPrivacyPolicy(
                                    parentContext);
                              },
                              child: Text(
                                LocaleKeys.signIn_privacyPolicy.tr(),
                                style: TextStyle(
                                  color: AppFlowyTheme.of(parentContext)
                                      .textColorScheme
                                      .action,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text('、'),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                LegalDocumentNavigator
                                    .navigateToPersonalInfoProtection(
                                        parentContext);
                              },
                              child: Text(
                                LocaleKeys.signIn_personalInfoProtection.tr(),
                                style: TextStyle(
                                  color: AppFlowyTheme.of(parentContext)
                                      .textColorScheme
                                      .action,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(LocaleKeys.signIn_disagree.tr()),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _agreed = true;
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(LocaleKeys.signIn_agreeAndContinue.tr()),
                      ),
                    ],
                  ),
                );
                return;
              }
              // 这里可以添加实际的登录/注册逻辑，当前先打印日志
              if (isEmail(emailOrPhone)) {
                debugPrint('用户输入的是邮箱地址: ' + emailOrPhone);
              } else {
                debugPrint('用户输入的是手机号: ' + emailOrPhone);
              }
            },
          ),
          VSpace(theme.spacing.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 20.0,
                child: Checkbox(
                  value: _agreed,
                  onChanged: (value) {
                    setState(() {
                      _agreed = value ?? false;
                    });
                  },
                ),
              ),
              const HSpace(4.0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.start,
                    children: [
                      Text(LocaleKeys.signIn_agreePrefix.tr()),
                      GestureDetector(
                        onTap: () {
                          LegalDocumentNavigator.navigateToUserAgreement(
                              context);
                        },
                        child: Text(
                          LocaleKeys.signIn_userAgreement.tr(),
                          style: TextStyle(
                              color: theme.textColorScheme.action,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                      Text(LocaleKeys.signIn_and.tr()),
                      GestureDetector(
                        onTap: () {
                          LegalDocumentNavigator.navigateToPrivacyPolicy(
                              context);
                        },
                        child: Text(
                          LocaleKeys.signIn_privacyPolicy.tr(),
                          style: TextStyle(
                              color: theme.textColorScheme.action,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
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
