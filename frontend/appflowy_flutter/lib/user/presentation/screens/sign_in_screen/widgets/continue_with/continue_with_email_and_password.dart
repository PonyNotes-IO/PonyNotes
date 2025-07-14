import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/password/password_check_service.dart';
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
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';

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
  bool _isLoading = false;

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
        if (successOrFail != null) {
          successOrFail.fold(
            (userProfile) async {
              emailKey.currentState?.clearError();
            },
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
          AFFilledTextButton.primary(
            text: _isLoading
                ? LocaleKeys.signIn_signingIn.tr()
                : LocaleKeys.signIn_loginOrRegister.tr(),
            size: AFButtonSize.l,
            alignment: Alignment.center,
            onTap: _isLoading
                ? () {}
                : () {
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
                              Text(LocaleKeys
                                  .signIn_pleaseReadAndAgreeBeforeLogin
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
                                      LegalDocumentNavigator
                                          .navigateToUserAgreement(
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
                                      LegalDocumentNavigator
                                          .navigateToPrivacyPolicy(
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
                                      LocaleKeys.signIn_personalInfoProtection
                                          .tr(),
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
                              child:
                                  Text(LocaleKeys.signIn_agreeAndContinue.tr()),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    if (isEmail(emailOrPhone)) {
                      _signInWithEmail(context, emailOrPhone);
                    } else {}
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
        ],
      ),
    );
  }

  void _signInWithEmail(BuildContext context, String input) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用通用的密码检查服务
      final authInfoResult =
          await PasswordCheckService.getUserAuthInfo(email: input);

      if (!mounted) return;

      authInfoResult.fold(
        (authInfo) {
          // 如果用户存在且有自定义密码，跳转到密码登录
          if (authInfo.exists && authInfo.hasCustomPassword) {
            _pushContinueWithPasswordPage(context, input);
          }
          // 如果用户不存在或存在但没有自定义密码，都跳转到验证码登录
          else {
            context
                .read<SignInBloc>()
                .add(SignInEvent.signInWithMagicLink(email: input));
            _pushContinueWithMagicLinkOrPasscodePage(context, input);
          }
        },
        (error) {
          _showUserCheckFailedDialog(context, input, error.msg);
        },
      );
    } catch (e) {
      // 处理异常
      if (mounted) {
        _showUserCheckFailedDialog(context, input, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUserCheckFailedDialog(
    BuildContext context,
    String email,
    String errorMessage,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('用户检查失败'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '无法检查用户状态，请选择继续方式：',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(LocaleKeys.button_cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              _signInWithEmail(context, email);
            },
            child: const Text('重试'),
          ),
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              _pushContinueWithPasswordPage(context, email);
            },
            child: const Text('密码登录'),
          ),
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              context
                  .read<SignInBloc>()
                  .add(SignInEvent.signInWithMagicLink(email: email));
              _pushContinueWithMagicLinkOrPasscodePage(context, email);
            },
            child: const Text('验证码登录'),
          ),
        ],
      ),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: signInBloc,
          child: ContinueWithMagicLinkOrPasscodePage(
            email: email,
            backToLogin: () {
              // 先重置状态，避免重复推送
              _hasPushedContinueWithMagicLinkOrPasscodePage = false;

              // 清理邮箱输入框的错误状态
              emailKey.currentState?.clearError();

              // 最后执行导航
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
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
            onEnterPassword: (password) {
              signInBloc.add(
                SignInEvent.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                ),
              );
            },
            onForgotPassword: () {
              // todo: implement forgot password
            },
          ),
        ),
      ),
    );
  }
}
