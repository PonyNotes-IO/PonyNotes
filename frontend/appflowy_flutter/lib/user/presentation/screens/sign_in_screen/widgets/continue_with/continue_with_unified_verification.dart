import 'dart:async';

import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';

import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/validator.dart';
import 'package:easy_localization/easy_localization.dart';

enum VerificationType { email, phone }

class ContinueWithUnifiedVerification extends StatefulWidget {
  const ContinueWithUnifiedVerification({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  State<ContinueWithUnifiedVerification> createState() => _ContinueWithUnifiedVerificationState();
}

class _ContinueWithUnifiedVerificationState extends State<ContinueWithUnifiedVerification> {
  final inputController = TextEditingController();
  final codeController = TextEditingController();
  final inputFocusNode = FocusNode();
  final codeFocusNode = FocusNode();
  final inputKey = GlobalKey<AFTextFieldState>();
  final codeKey = GlobalKey<AFTextFieldState>();

  bool _agreed = false;
  bool _isCodeSent = false;
  int _countdown = 0;
  Timer? _timer;
  VerificationType? _currentType;

  @override
  void dispose() {
    inputController.dispose();
    codeController.dispose();
    inputFocusNode.dispose();
    codeFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.successOrFail;
        if (successOrFail != null) {
          successOrFail.fold(
            (userProfile) {
              // 登录成功，由上层处理导航
            },
            (error) {
              final errorMessage = error.msg;
              if (_isCodeSent) {
                codeKey.currentState?.syncError(errorText: errorMessage);
              } else {
                inputKey.currentState?.syncError(errorText: errorMessage);
              }
            },
          );
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
              TitleLogo(
                title: _isCodeSent 
                    ? (_currentType == VerificationType.email 
                        ? LocaleKeys.signIn_enterVerificationCode.tr()
                        : "输入短信验证码")
                    : "邮箱/手机验证码登录",
                description: _isCodeSent 
                    ? "验证码已发送到 ${inputController.text}"
                    : "请输入您的邮箱地址或手机号码",
              ),
              
              const VSpace(24),
              
              // 邮箱/手机号输入框
              AFTextField(
                key: inputKey,
                controller: inputController,
                focusNode: inputFocusNode,
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
                hintText: "邮箱地址或手机号码",
                readOnly: _isCodeSent, // 发送验证码后设为只读
                onChanged: (value) {
                  setState(() {
                    _currentType = _detectInputType(value);
                  });
                },
                onSubmitted: (_) => _sendVerificationCode(),
              ),
              
              if (_isCodeSent) ...[
                const VSpace(16),
                // 验证码输入框
                Row(
                  children: [
                    Expanded(
                      child: AFTextField(
                        key: codeKey,
                        controller: codeController,
                        focusNode: codeFocusNode,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        hintText: "请输入验证码",
                        onSubmitted: (_) => _login(),
                      ),
                    ),
                    const HSpace(12),
                    // 重新发送按钮
                    SizedBox(
                      width: 120,
                      child: PrimaryRoundedButton(
                        text: _countdown > 0 ? '${_countdown}s' : '重新发送',
                        onTap: _countdown > 0 ? null : _sendVerificationCode,
                        backgroundColor: _countdown > 0 
                            ? Colors.grey.shade300 
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
              
              const VSpace(24),
              
              // 用户协议
              _buildAgreement(),
              
              const VSpace(16),
              
              // 登录按钮
              PrimaryRoundedButton(
                text: _isCodeSent ? "登录" : "发送验证码",
                onTap: (_agreed && widget.enabled) ? (_isCodeSent ? _login : _sendVerificationCode) : null,
                backgroundColor: (_agreed && widget.enabled) 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300,
              ),
              
              const VSpace(16),
              
              // 返回按钮
              OutlinedRoundedButton(
                text: _isCodeSent ? "返回修改联系方式" : "返回其他登录方式",
                onTap: () {
                  if (_isCodeSent) {
                    setState(() {
                      _isCodeSent = false;
                      _countdown = 0;
                      _timer?.cancel();
                      codeController.clear();
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreement() {
    return Row(
      children: [
        Checkbox(
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const HSpace(8),
        Expanded(
          child: Wrap(
            children: [
              const Text("我已阅读并同意 "),
              GestureDetector(
                onTap: () => _showLegalDoc("用户协议"),
                child: Text(
                  "用户协议",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(" 和 "),
              GestureDetector(
                onTap: () => _showLegalDoc("隐私政策"),
                child: Text(
                  "隐私政策",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 检测输入类型
  VerificationType? _detectInputType(String input) {
    if (input.isEmpty) return null;
    
    // 检测邮箱
    if (_isValidEmail(input)) {
      return VerificationType.email;
    }
    
    // 检测手机号
    if (_isValidPhoneNumber(input)) {
      return VerificationType.phone;
    }
    
    return null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhoneNumber(String phone) {
    // 使用统一的验证器
    return Validator.isValidPhone(phone);
  }

  void _showLegalDoc(String title) {
    // 显示法律文档
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('显示$title'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先同意用户协议和隐私政策'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final input = inputController.text.trim();
    if (input.isEmpty) {
      inputKey.currentState?.syncError(errorText: '请输入邮箱地址或手机号码');
      return;
    }

    final inputType = _detectInputType(input);
    if (inputType == null) {
      inputKey.currentState?.syncError(errorText: '请输入正确的邮箱地址或手机号码格式');
      return;
    }

    setState(() {
      _currentType = inputType;
    });

    try {
      if (inputType == VerificationType.email) {
        // 发送邮箱验证码
        context.read<SignInBloc>().add(
          SignInEvent.signInWithMagicLink(email: input),
        );
      } else {
        // 发送短信验证码，使用清理后的手机号
        final cleanPhone = Validator.cleanPhoneNumber(input);
        await _sendSmsCode(cleanPhone);
      }

      setState(() {
        _isCodeSent = true;
        _countdown = 60;
      });

      inputKey.currentState?.clearError();
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inputType == VerificationType.email 
                ? '验证码已发送到您的邮箱' 
                : '验证码已发送到您的手机',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // 自动聚焦到验证码输入框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        codeFocusNode.requestFocus();
      });

    } catch (e) {
      inputKey.currentState?.syncError(errorText: '发送验证码失败: $e');
    }
  }

  Future<void> _sendSmsCode(String phone) async {
    // 使用后端服务发送短信验证码
    try {
      final result = await UserBackendService.sendSmsCode(phone);
      result.fold(
        (success) {
          // 发送成功
        },
        (error) {
          throw Exception('发送短信失败: ${error.msg}');
        },
      );
    } catch (e) {
      throw Exception('发送短信验证码失败: $e');
    }
  }

  Future<void> _login() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先同意用户协议和隐私政策'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final input = inputController.text.trim();
    final code = codeController.text.trim();

    if (input.isEmpty) {
      inputKey.currentState?.syncError(errorText: '请输入邮箱地址或手机号码');
      return;
    }

    if (code.isEmpty) {
      codeKey.currentState?.syncError(errorText: '请输入验证码');
      return;
    }

    if (code.length != 6) {
      codeKey.currentState?.syncError(errorText: '验证码必须是6位数字');
      return;
    }

    // 开始登录

    // 根据类型调用不同的登录事件
    if (_currentType == VerificationType.email) {
      context.read<SignInBloc>().add(
        SignInEvent.signInWithPasscode(
          email: input,
          passcode: code,
        ),
      );
    } else {
      // 使用清理后的手机号
      final cleanPhone = Validator.cleanPhoneNumber(input);
      context.read<SignInBloc>().add(
        SignInEvent.signInWithPhoneSms(
          phone: cleanPhone,
          code: code,
        ),
      );
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }
}
