import 'dart:async';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

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
  final List<TextEditingController> _codeControllers = List.generate(
    6, 
    (index) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    6, 
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // 自动聚焦到第一个验证码输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    try {
      // 清空当前验证码输入
      for (final controller in _codeControllers) {
        controller.clear();
      }
      setState(() => _errorMessage = '');
      
      // 聚焦到第一个输入框
      _codeFocusNodes[0].requestFocus();
      
      // 调用SignInBloc重新发送邮箱验证码
    context
        .read<SignInBloc>()
        .add(SignInEvent.signInWithMagicLink(email: widget.email));
      
      // 重新开始倒计时
    _startCountdown();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('验证码已重新发送到您的邮箱'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = '重新发送失败: $e');
    }
  }

  void _validateAndSubmit() {
    final code = _codeControllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      setState(() => _errorMessage = '验证码错误，请重新输入');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    widget.onEnterPasscode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.successOrFail;
        if (successOrFail != null) {
            setState(() => _isLoading = false);
            successOrFail.fold(
              (userProfile) async {
                setState(() => _errorMessage = '');
                // 登录成功的处理逻辑在上层组件
              },
              (error) {
                setState(() => _errorMessage = error.msg);
              },
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // 状态栏
              _buildStatusBar(),
              
              // 返回按钮
              _buildBackButton(),
              
              // 主要内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const VSpace(40),
                      
                      // 标题
                      const Text(
                        '请输入验证码',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const VSpace(20),
                      
                      // 验证码发送信息
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF777777),
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: '6位验证码已发送至'),
                            TextSpan(
                              text: ' ${widget.email}',
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: '，有效期15分钟。'),
                          ],
                        ),
                      ),
                      const VSpace(80),
                      
                      // 验证码输入框
                      _buildVerificationCodeInputs(),
                      
                      const VSpace(20),
                      
                      // 错误提示
                      if (_errorMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      
                      const VSpace(40),
                      
                      // 重新发送验证码
                      _buildResendSection(),
                      
                      const VSpace(40),
                      
                      // 下一步按钮
                      _buildNextButton(),
                      
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 5),
      child: Row(
        children: [
          const Text(
            '9:41',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          const HSpace(8),
          const Text(
            'Mon Jun 10',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // 信号图标
          Container(
            width: 35,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const HSpace(4),
          const Text(
            '100%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          const HSpace(3),
          // 电池图标
          Container(
            width: 27,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.only(left: 89, top: 75),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          size: 24,
          color: Color(0xFF333333),
        ),
        onPressed: widget.backToLogin,
      ),
    );
  }

  Widget _buildVerificationCodeInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: EdgeInsets.only(right: index < 5 ? 12 : 0),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_codeControllers[index].text.isEmpty && index > 0) {
                    // 如果当前输入框为空且不是第一个，则跳到前一个输入框并清空
                    _codeFocusNodes[index - 1].requestFocus();
                    _codeControllers[index - 1].clear();
                  }
                }
              },
              child: TextField(
                controller: _codeControllers[index],
                focusNode: _codeFocusNodes[index],
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
                expands: true,
                // ignore: avoid_redundant_argument_values
                minLines: null,
                // ignore: avoid_redundant_argument_values
                maxLines: null,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFF89575), width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  // 清除错误信息
                  if (_errorMessage.isNotEmpty) {
                    setState(() => _errorMessage = '');
                  }
                  
                  // 只保留最后一个字符
                  if (value.length > 1) {
                    _codeControllers[index].text = value.substring(value.length - 1);
                    _codeControllers[index].selection = TextSelection.fromPosition(
                      TextPosition(offset: _codeControllers[index].text.length),
                    );
                  }
                  if (value.isNotEmpty && index < 5) {
                    _codeFocusNodes[index + 1].requestFocus();
                  }
                  final isAllFilled = _codeControllers.every((c) => c.text.isNotEmpty);
                  if (isAllFilled) {
                    _validateAndSubmit();
                  }
                },
                onTap: () {
                  // 点击时清空当前输入框并聚焦
                  _codeControllers[index].clear();
                  _codeFocusNodes[index].requestFocus();
                },
                onSubmitted: (_) {
                  if (index < 5) {
                    _codeFocusNodes[index + 1].requestFocus();
                  } else {
                    _validateAndSubmit();
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '收不到验证码？',
          style: TextStyle(
            color: Color(0xFF5E5E5E),
            fontSize: 20,
          ),
        ),
        const HSpace(12),
        if (_countdown > 0)
          SizedBox(
            width: 211,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$_countdown',
                    style: const TextStyle(
                      color: Color(0xFFF89575),
                    ),
                  ),
                  const TextSpan(
                    text: '秒后重新获取验证码',
                    style: TextStyle(
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GestureDetector(
            onTap: _resendCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF89575),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '重新获取验证码',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                                fontWeight: FontWeight.w500,
                ),
                              ),
                        ),
                      ),
                  ],
    );
  }

  Widget _buildNextButton() {
                    return SizedBox(
      width: 418,
      height: 52,
                      child: ElevatedButton(
        onPressed: _isLoading ? null : _validateAndSubmit,
                        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF89575),
                          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                '下一步',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
