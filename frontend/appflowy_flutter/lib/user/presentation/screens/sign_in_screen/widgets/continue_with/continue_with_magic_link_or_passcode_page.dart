import 'dart:async';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'verification_code_input.dart';

class ContinueWithMagicLinkOrPasscodePage extends StatefulWidget {
  const ContinueWithMagicLinkOrPasscodePage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.onEnterPasscode,
  });

  final String email;
  final VoidCallback backToLogin;
  final ValueChanged<String> onEnterPasscode;

  @override
  State<ContinueWithMagicLinkOrPasscodePage> createState() =>
      _ContinueWithMagicLinkOrPasscodePageState();
}

class _ContinueWithMagicLinkOrPasscodePageState
    extends State<ContinueWithMagicLinkOrPasscodePage> {
  String errorText = '';
  bool isSubmitting = false;
  int countdown = 59;
  bool canResend = false;
  late final TextEditingController _codeController;
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _startCountdown();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // 取消所有计时器
    _timer?.cancel();
    _timer = null;

    // 立即清理控制器
    try {
      _codeController.dispose();
    } catch (e) {
      // 忽略 dispose 错误
    }

    super.dispose();
  }

  void _startCountdown() {
    if (_isDisposed || !mounted) return;

    setState(() {
      countdown = 59;
      canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }

      if (countdown <= 1) {
        timer.cancel();
        if (mounted && !_isDisposed) {
          setState(() {
            canResend = true;
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            countdown--;
          });
        }
      }
    });
  }

  void _onResend() {
    if (!canResend || !mounted || _isDisposed) return;
    context
        .read<SignInBloc>()
        .add(SignInEvent.signInWithMagicLink(email: widget.email));
    _startCountdown();
  }

  void _onCompleted(String code) {
    if (!mounted || _isDisposed || isSubmitting) return;

    setState(() {
      isSubmitting = true;
      errorText = '';
    });
    widget.onEnterPasscode(code);
  }

  void _onError(String error) {
    if (!mounted || _isDisposed) return;

    setState(() {
      errorText = error;
      isSubmitting = false;
    });

    // 安全地清空输入框
    if (mounted && !_isDisposed && _codeController.hasListeners) {
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        // 严格检查组件是否仍然活跃
        if (!mounted || !context.mounted || _isDisposed) return;

        final successOrFail = state.successOrFail;
        if (successOrFail != null) {
          if (successOrFail.isSuccess) {
            // autoconfirm或验证码登录成功，原本跳转主界面的逻辑已删除
            if (mounted && !_isDisposed) {
              setState(() {
                isSubmitting = false;
                errorText = '';
              });
            }
          } else if (successOrFail.isFailure) {
            // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在下一帧执行
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted && !_isDisposed) {
                _onError(LocaleKeys.signIn_invalidVerificationCode.tr());
              }
            });
          }
        }

        if (state.isSubmitting != isSubmitting && mounted && !_isDisposed) {
          setState(() => isSubmitting = state.isSubmitting);
        }
      },
      child: Scaffold(
        body: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              color: theme.surfaceColorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.signIn_enterVerificationCode.tr(),
                  style: theme.textStyle.title.standard().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${LocaleKeys.signIn_temporaryVerificationCodeSent.tr()}\n${widget.email}',
                  style: theme.textStyle.body.standard().copyWith(
                        color: theme.textColorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 16),
                VerificationCodeInput(
                  key: const ValueKey('verification_code_input'),
                  controller: _codeController,
                  onChanged: (_) {
                    if (errorText.isNotEmpty && mounted && !_isDisposed) {
                      setState(() => errorText = '');
                    }
                  },
                  errorText: errorText,
                  length: 6,
                  autoFocus: true,
                ),
                if (errorText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorText,
                      style: theme.textStyle.body.standard().copyWith(
                            color: theme.textColorScheme.error,
                            fontSize: 14,
                          ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      canResend
                          ? LocaleKeys.signIn_resendCode.tr()
                          : LocaleKeys.signIn_resendCodeIn
                              .tr(args: [countdown.toString()]),
                      style: theme.textStyle.body.standard().copyWith(
                            color: canResend
                                ? theme.textColorScheme.action
                                : theme.textColorScheme.secondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                    ),
                    if (canResend)
                      TextButton(
                        onPressed: _onResend,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          LocaleKeys.signIn_resendCode.tr(),
                          style: theme.textStyle.body.standard().copyWith(
                                color: theme.textColorScheme.action,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _codeController,
                  builder: (context, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _codeController.text.length == 6 && !isSubmitting
                                ? () => _onCompleted(_codeController.text)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.textColorScheme.secondary,
                          foregroundColor: Colors.white,
                          textStyle: theme.textStyle.body.standard().copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Text(LocaleKeys.web_continue.tr()),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.backToLogin,
                  child: Text(LocaleKeys.signIn_backToLogin.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
