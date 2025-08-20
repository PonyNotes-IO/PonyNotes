import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/douyin_qr_login_dialog.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import 'third_party_sign_in_button.dart';

typedef _SignInCallback = void Function(ThirdPartySignInButtonType signInType);

@visibleForTesting
const Key signInWithGoogleButtonKey = Key('signInWithGoogleButton');

class ThirdPartySignInButtons extends StatelessWidget {
  /// Used in DesktopSignInScreen, MobileSignInScreen and SettingThirdPartyLogin
  const ThirdPartySignInButtons({
    super.key,
    this.expanded = false,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isDesktopOrWeb) {
      return _DesktopThirdPartySignIn(
        onSignIn: (type) => _signIn(context, type.provider),
      );
    } else {
      return _MobileThirdPartySignIn(
        isExpanded: expanded,
        onSignIn: (type) => _signIn(context, type.provider),
      );
    }
  }

  void _signIn(BuildContext context, String provider) {
    // 特殊处理抖音登录，显示二维码对话框
    if (provider == 'douyin') {
      _showDouyinQRLogin(context);
      return;
    }
    
    context.read<SignInBloc>().add(
          SignInEvent.signInWithOAuth(platform: provider),
        );
  }

  void _showDouyinQRLogin(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DouyinQRLoginDialog(
        onLoginSuccess: () {
          Navigator.of(context).pop();
          // 这里可以触发登录成功的逻辑
          // 实际应该通过SignInBloc处理
        },
        onLoginError: (error) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败: $error')),
          );
        },
      ),
    );
  }
}

class _DesktopThirdPartySignIn extends StatefulWidget {
  const _DesktopThirdPartySignIn({
    required this.onSignIn,
  });

  final _SignInCallback onSignIn;

  @override
  State<_DesktopThirdPartySignIn> createState() =>
      _DesktopThirdPartySignInState();
}

class _DesktopThirdPartySignInState extends State<_DesktopThirdPartySignIn> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
            type: ThirdPartySignInButtonType.wechat,
            onTap: () => widget.onSignIn(ThirdPartySignInButtonType.wechat),
          ),
          _CircleIconButton(
            type: ThirdPartySignInButtonType.tikTok,
            onTap: () => widget.onSignIn(ThirdPartySignInButtonType.tikTok),
          ),
          _CircleIconButton(
            type: ThirdPartySignInButtonType.qq,
            onTap: () => widget.onSignIn(ThirdPartySignInButtonType.qq),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.type,
    required this.onTap,
  });

  final ThirdPartySignInButtonType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: FlowySvg(
            type.icon,
            size: const Size.square(29),
            blendMode: type.blendMode,
          ),
        ),
      ),
    );
  }
}

class _MobileThirdPartySignIn extends StatefulWidget {
  const _MobileThirdPartySignIn({
    required this.isExpanded,
    required this.onSignIn,
  });

  final bool isExpanded;
  final _SignInCallback onSignIn;

  @override
  State<_MobileThirdPartySignIn> createState() =>
      _MobileThirdPartySignInState();
}

class _MobileThirdPartySignInState extends State<_MobileThirdPartySignIn> {
  static const padding = 8.0;

  bool isExpanded = false;

  @override
  void initState() {
    super.initState();

    isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MobileThirdPartySignInButton(
          type: ThirdPartySignInButtonType.wechat,
          onTap: () => widget.onSignIn(ThirdPartySignInButtonType.wechat),
        ),
        const VSpace(padding),
        MobileThirdPartySignInButton(
          type: ThirdPartySignInButtonType.tikTok,
          onTap: () => widget.onSignIn(ThirdPartySignInButtonType.tikTok),
        ),
        const VSpace(padding),
        MobileThirdPartySignInButton(
          type: ThirdPartySignInButtonType.qq,
          onTap: () => widget.onSignIn(ThirdPartySignInButtonType.qq),
        ),
        /*
        // only display apple sign in button on iOS
        if (Platform.isIOS) ...[
          MobileThirdPartySignInButton(
            type: ThirdPartySignInButtonType.apple,
            onTap: () => widget.onSignIn(ThirdPartySignInButtonType.apple),
          ),
          const VSpace(padding),
        ],
        MobileThirdPartySignInButton(
          key: signInWithGoogleButtonKey,
          type: ThirdPartySignInButtonType.google,
          onTap: () => widget.onSignIn(ThirdPartySignInButtonType.google),
        ),
        ...isExpanded ? _buildExpandedButtons() : _buildCollapsedButtons(),
        */
      ],
    );
  }


}
