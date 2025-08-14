import 'dart:async';

import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinueWithPhoneSms extends StatefulWidget {
  const ContinueWithPhoneSms({super.key});

  @override
  State<ContinueWithPhoneSms> createState() => _ContinueWithPhoneSmsState();
}

class _ContinueWithPhoneSmsState extends State<ContinueWithPhoneSms> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final phoneFocusNode = FocusNode();
  final codeFocusNode = FocusNode();
  final phoneKey = GlobalKey<AFTextFieldState>();
  final codeKey = GlobalKey<AFTextFieldState>();

  bool _agreed = false;
  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _isCodeLoading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    phoneFocusNode.dispose();
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
          setState(() => _isLoading = false);
          successOrFail.fold(
            (userProfile) async {
              phoneKey.currentState?.clearError();
              codeKey.currentState?.clearError();
              // 登录成功的处理逻辑在上层组件
            },
            (error) {
              phoneKey.currentState?.syncError(errorText: error.msg);
              codeKey.currentState?.syncError(errorText: error.msg);
            },
          );
        }
      },
      child: Column(
        children: [
          const TitleLogo(
            title: '手机号登录',
            description: '请输入手机号码进行登录',
          ),
          const VSpace(24),
          
          // 手机号输入框
          AFTextField(
            key: phoneKey,
            controller: phoneController,
            focusNode: phoneFocusNode,
            autoFocus: true,
            obscureText: false,
            keyboardType: TextInputType.phone,

            hintText: "请输入手机号",

            onSubmitted: (_) => _sendSmsCode(),
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
                    onTap: _countdown > 0 ? null : _sendSmsCode,
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
            onTap: _agreed ? (_isCodeSent ? _login : _sendSmsCode) : null,
            backgroundColor: _agreed 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade300,
          ),
          
          const VSpace(16),
          
          // 返回按钮
          OutlinedRoundedButton(
            text: "返回其他登录方式",
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreement() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const HSpace(8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              children: [
                const TextSpan(text: "我已阅读并同意"),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showDocument('用户协议'),
                    child: Text(
                      "《用户协议》",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: "和"),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showDocument('隐私政策'),
                    child: Text(
                      "《隐私政策》",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDocument(String title) {
    // 显示法律文档
    showMessageToast('显示$title');
  }

  Future<void> _sendSmsCode() async {
    if (!_agreed) {
      showMessageToast(
         '请先同意用户协议和隐私政策',
        
      );
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      phoneKey.currentState?.syncError(errorText: '请输入手机号');
      return;
    }

    if (!_isValidPhoneNumber(phone)) {
      phoneKey.currentState?.syncError(errorText: '请输入正确的手机号格式');
      return;
    }

    setState(() => _isCodeLoading = true);

    try {
      // 调用后端API发送短信验证码
      final result = await UserBackendService.sendSmsCode(phone);
      
      result.fold(
        (success) {
          setState(() {
            _isCodeSent = true;
            _isCodeLoading = false;
            _countdown = 60;
          });
          
          phoneKey.currentState?.clearError();
          _startCountdown();
          
          showMessageToast(
             '验证码已发送到您的手机',
            
          );

          // 自动聚焦到验证码输入框
          WidgetsBinding.instance.addPostFrameCallback((_) {
            codeFocusNode.requestFocus();
          });
        },
        (error) {
          setState(() => _isCodeLoading = false);
          phoneKey.currentState?.syncError(errorText: '发送验证码失败: ${error.msg}');
        },
      );
      
    } catch (e) {
      setState(() => _isCodeLoading = false);
      phoneKey.currentState?.syncError(errorText: '发送验证码失败: $e');
    }
  }

  Future<void> _login() async {
    if (!_agreed) {
      showMessageToast(
         '请先同意用户协议和隐私政策',
        
      );
      return;
    }

    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

    if (phone.isEmpty) {
      phoneKey.currentState?.syncError(errorText: '请输入手机号');
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

    setState(() => _isLoading = true);
    
    // 调用登录事件
    context.read<SignInBloc>().add(
      SignInEvent.signInWithPhoneSms(
        phone: phone,
        code: code,
      ),
    );
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

  bool _isValidPhoneNumber(String phone) {
    // 简单的中国手机号验证
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }
}
