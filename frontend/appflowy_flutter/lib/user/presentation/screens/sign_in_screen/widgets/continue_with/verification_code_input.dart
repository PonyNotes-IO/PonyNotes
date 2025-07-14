import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerificationCodeInput extends StatefulWidget {
  const VerificationCodeInput({
    super.key,
    this.onChanged,
    this.errorText = '',
    this.length = 6,
    this.autoFocus = true,
    this.controller,
  });

  final Function(String)? onChanged;
  final String errorText;
  final int length;
  final bool autoFocus;
  final TextEditingController? controller;

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (widget.controller == null) {
      _controller.dispose();
    }
    // 添加安全检查，确保FocusNode没有被重复销毁
    try {
      _focusNode.dispose();
    } catch (e) {
      // 忽略重复销毁的错误
    }
    super.dispose();
  }

  void clearInput() {
    if (!_isDisposed && mounted && !_controller.text.isEmpty) {
      _controller.clear();
    }
  }

  void requestFocus() {
    if (!_isDisposed &&
        mounted &&
        _focusNode.canRequestFocus &&
        !_focusNode.hasFocus) {
      try {
        _focusNode.requestFocus();
      } catch (e) {
        // 忽略FocusNode已被销毁的错误
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinCodeTextField(
          appContext: context,
          length: widget.length,
          controller: _controller,
          focusNode: _focusNode,
          autoFocus: widget.autoFocus,
          keyboardType: TextInputType.number,
          enableActiveFill: true,
          autoDismissKeyboard: false, // 修改：不自动关闭键盘，让用户可以继续编辑
          enablePinAutofill: true,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            if (!_isDisposed && mounted) {
              widget.onChanged?.call(value);

              // 当输入满6位时，自动关闭键盘并失去焦点
              if (value.length == widget.length) {
                try {
                  _focusNode.unfocus();
                } catch (e) {
                  // 忽略FocusNode已被销毁的错误
                }
              }
            }
          },
          // 移除 onCompleted 回调，不再自动提交
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 48,
            fieldWidth: 48,
            activeFillColor: theme.surfaceColorScheme.primary,
            inactiveFillColor: theme.surfaceColorScheme.primary,
            selectedFillColor: theme.surfaceColorScheme.primary,
            activeColor: theme.borderColorScheme.primary,
            inactiveColor: theme.borderColorScheme.primary,
            selectedColor: theme.borderColorScheme.primary,
            errorBorderColor: theme.textColorScheme.error,
            borderWidth: 1,
            activeBorderWidth: 2,
            selectedBorderWidth: 2,
            errorBorderWidth: 2,
          ),
          animationType: AnimationType.fade,
          textStyle: theme.textStyle.body.standard().copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: Colors.transparent,
          errorAnimationController: null,
          errorTextSpace: 30,
          showCursor: true,
          cursorWidth: 20,
          cursorHeight: 20,
          cursorColor: theme.textColorScheme.primary,
          readOnly: false,
          beforeTextPaste: (text) {
            // 允许粘贴数字
            return text != null && RegExp(r'^[0-9]+$').hasMatch(text);
          },
        ),
        if (widget.errorText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText,
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
