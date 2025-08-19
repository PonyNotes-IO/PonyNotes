import 'dart:async';

import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/title_logo.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_phone_sms_page.dart';

import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinueWithPhoneSms extends StatefulWidget {
  const ContinueWithPhoneSms({super.key});

  @override
  State<ContinueWithPhoneSms> createState() => _ContinueWithPhoneSmsState();
}

class _ContinueWithPhoneSmsState extends State<ContinueWithPhoneSms> {
  final phoneController = TextEditingController();
  final phoneFocusNode = FocusNode();
  final phoneKey = GlobalKey<AFTextFieldState>();

  bool _agreed = false;
  bool _isCodeSent = false;
  String _currentPhone = '';

  @override
  void dispose() {
    phoneController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.successOrFail;
        if (successOrFail != null) {
          successOrFail.fold(
            (userProfile) async {
              phoneKey.currentState?.clearError();
              // 登录成功的处理逻辑在上层组件
            },
            (error) {
              phoneKey.currentState?.syncError(errorText: error.msg);
            },
          );
        }
      },
      child: _isCodeSent 
          ? ContinueWithPhoneSmsPage(
              phone: _currentPhone,
              backToLogin: () {
                setState(() {
                  _isCodeSent = false;
                  _currentPhone = '';
                });
              },
              onVerifySms: (code) {
                // 重置SignInBloc状态，确保没有进行中的操作阻止新的请求
                final signInBloc = context.read<SignInBloc>();
                signInBloc.add(const SignInEvent.cancel());
                // 给一点时间让cancel事件处理完成
                Future.delayed(const Duration(milliseconds: 100), () {
                  signInBloc.add(
                    SignInEvent.signInWithPhoneSms(
                      phone: _currentPhone,
                      code: code,
                    ),
                  );
                });
              },
            )
          : _buildPhoneInputPage(),
    );
  }

  Widget _buildPhoneInputPage() {
    return Column(
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
          keyboardType: TextInputType.phone,
          hintText: "请输入手机号",
          onSubmitted: (_) => _sendSmsCode(),
        ),
        
        const VSpace(24),
        
        // 用户协议
        _buildAgreement(),
        
        const VSpace(16),
        
        // 发送验证码按钮
        PrimaryRoundedButton(
          text: "发送验证码",
          onTap: _agreed ? _sendSmsCode : null,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('显示$title'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendSmsCode() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先同意用户协议和隐私政策'),
          duration: Duration(seconds: 2),
        ),
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

    try {
      // 调用后端API发送短信验证码
      final result = await UserBackendService.sendSmsCode(phone);
      
      result.fold(
        (success) {
          setState(() {
            _isCodeSent = true;
            _currentPhone = phone;
          });
          
          phoneKey.currentState?.clearError();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('验证码已发送到您的手机'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        (error) {
          phoneKey.currentState?.syncError(errorText: '发送验证码失败: ${error.msg}');
        },
      );
      
    } catch (e) {
      phoneKey.currentState?.syncError(errorText: '发送验证码失败: $e');
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // 简单的中国手机号验证
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }
}
