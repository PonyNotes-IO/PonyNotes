import 'dart:async';

import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class IdentityVerificationDialog extends StatefulWidget {
  const IdentityVerificationDialog({
    super.key,
    required this.phoneNumber,
    this.onVerificationComplete,
  });

  final String phoneNumber;
  final VoidCallback? onVerificationComplete;

  @override
  State<IdentityVerificationDialog> createState() => _IdentityVerificationDialogState();
}

class _IdentityVerificationDialogState extends State<IdentityVerificationDialog> {
  final codeController = TextEditingController();
  final codeFocusNode = FocusNode();
  bool _isCodeSent = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    codeController.dispose();
    codeFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Dialog(
      backgroundColor: theme.surfaceColorScheme.layer01,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FlowyText(
                  '身份验证',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textColorScheme.primary,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            
            const VSpace(8),
            
            // 描述文字
            FlowyText(
              '为了你的账户安全，请先验证身份',
              fontSize: 14,
              color: theme.textColorScheme.secondary,
            ),
            
            const VSpace(24),
            
            // 手机号显示
            Row(
              children: [
                FlowyText(
                  '使用手机',
                  fontSize: 16,
                  color: theme.textColorScheme.primary,
                ),
                const Spacer(),
                FlowyText(
                  widget.phoneNumber,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textColorScheme.primary,
                ),
                const HSpace(8),
                FlowyText(
                  '验证',
                  fontSize: 16,
                  color: theme.textColorScheme.primary,
                ),
                const HSpace(8),
                GestureDetector(
                  onTap: () {
                    // TODO: 实现切换验证方式
                  },
                  child: Row(
                    children: [
                      FlowyText(
                        '切换验证',
                        fontSize: 14,
                        color: const Color(0xFF4285F4),
                      ),
                      const HSpace(4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Color(0xFF4285F4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const VSpace(16),
            
            // 验证通过提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const HSpace(8),
                  FlowyText(
                    '验证通过',
                    fontSize: 14,
                    color: const Color(0xFF059669),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
            
            const VSpace(24),
            
            // 验证码输入框
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        focusNode: codeFocusNode,
                        decoration: const InputDecoration(
                          hintText: '6位短信验证码',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    const HSpace(12),
                    GestureDetector(
                      onTap: _canResendCode() ? _sendVerificationCode : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _canResendCode() 
                              ? const Color(0xFF4285F4) 
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FlowyText(
                          _canResendCode() ? '重新获取' : '${_countdown}s',
                          fontSize: 14,
                          color: _canResendCode() ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const VSpace(8),
                FlowyText(
                  '已发送短信验证码到绑定手机',
                  fontSize: 12,
                  color: theme.textColorScheme.secondary,
                ),
              ],
            ),
            
            const VSpace(32),
            
            // 底部按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const HSpace(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: codeController.text.length == 6 ? _verifyCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canResendCode() {
    return _countdown == 0;
  }

  void _sendVerificationCode() {
    if (!_canResendCode()) return;
    
    setState(() {
      _isCodeSent = true;
      _countdown = 60;
    });
    
    _startCountdown();
    
    // TODO: 实际发送验证码的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('验证码已发送'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyCode() {
    if (codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入6位验证码'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // TODO: 实际验证码验证逻辑
    // 这里模拟验证成功
    widget.onVerificationComplete?.call();
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('验证成功'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 自动发送验证码
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationCode();
    });
  }
} 