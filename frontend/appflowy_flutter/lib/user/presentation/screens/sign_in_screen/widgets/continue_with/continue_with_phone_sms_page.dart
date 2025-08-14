import 'dart:async';

import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/application/user_service.dart';

import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinueWithPhoneSmsPage extends StatefulWidget {
  const ContinueWithPhoneSmsPage({
    super.key,
    required this.phone,
    required this.backToLogin,
    required this.onVerifySms,
  });

  final String phone;
  final VoidCallback backToLogin;
  final Function(String code) onVerifySms;

  @override
  State<ContinueWithPhoneSmsPage> createState() => _ContinueWithPhoneSmsPageState();
}

class _ContinueWithPhoneSmsPageState extends State<ContinueWithPhoneSmsPage> {
  final codeController = TextEditingController();
  final codeFocusNode = FocusNode();
  final codeKey = GlobalKey<AFTextFieldState>();

  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // 自动聚焦到验证码输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    codeController.dispose();
    codeFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.backToLogin,
        ),
        title: const Text('手机验证'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: BlocListener<SignInBloc, SignInState>(
        listener: (context, state) {
          final successOrFail = state.successOrFail;
          if (successOrFail != null) {
            setState(() => _isLoading = false);
            successOrFail.fold(
              (userProfile) async {
                codeKey.currentState?.clearError();
                // 登录成功的处理逻辑在上层组件
              },
              (error) {
                codeKey.currentState?.syncError(errorText: error.msg);
              },
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const VSpace(40),
              
              // 图标和标题
              const Icon(
                Icons.sms,
                size: 80,
                color: Color(0xFFF89575),
              ),
              const VSpace(24),
              
              const Text(
                '验证手机号',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const VSpace(16),
              
              Text(
                '我们已向 ${widget.phone} 发送了验证码\n请输入收到的6位验证码',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              const VSpace(32),
              
              // 验证码输入框
              AFTextField(
                key: codeKey,
                controller: codeController,
                focusNode: codeFocusNode,
                obscureText: false,
                keyboardType: TextInputType.number,
                hintText: "请输入6位验证码",
                onSubmitted: (_) => _verifyCode(),
              ),
              
              const VSpace(24),
              
              // 重新发送按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '没有收到验证码？',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _countdown > 0 || _isResending ? null : _resendCode,
                    child: Text(
                      _countdown > 0 
                          ? '重新发送 (${_countdown}s)'
                          : _isResending
                              ? '发送中...'
                              : '重新发送',
                      style: TextStyle(
                        color: _countdown > 0 || _isResending 
                            ? Colors.grey 
                            : const Color(0xFFF89575),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const VSpace(32),
              
              // 验证按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF89575),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '验证并登录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyCode() {
    final code = codeController.text.trim();
    
    if (code.isEmpty) {
      codeKey.currentState?.syncError(errorText: '请输入验证码');
      return;
    }
    
    if (code.length != 6) {
      codeKey.currentState?.syncError(errorText: '验证码必须是6位数字');
      return;
    }
    
    setState(() => _isLoading = true);
    widget.onVerifySms(code);
  }

  void _resendCode() async {
    setState(() => _isResending = true);
    
    try {
      final result = await UserBackendService.sendSmsCode(widget.phone);
      
      result.fold(
        (_) {
          showToastNotification(
            message: '验证码已重新发送',
            type: ToastificationType.success,
          );
          setState(() {
            _countdown = 60;
            _isResending = false;
          });
          _startCountdown();
        },
        (error) {
          showToastNotification(
            message: '重新发送失败: ${error.msg}',
            type: ToastificationType.error,
          );
          setState(() => _isResending = false);
        },
      );
    } catch (e) {
      showToastNotification(
        message: '重新发送失败: $e',
        type: ToastificationType.error,
      );
      setState(() => _isResending = false);
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
