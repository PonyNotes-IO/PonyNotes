import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum ThirdPartySignInButtonType {
  apple,
  google,
  github,
  discord,
  wechat,
  tikTok,
  qq,
  anonymous;

  String get provider {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return 'apple';
      case ThirdPartySignInButtonType.google:
        return 'google';
      case ThirdPartySignInButtonType.github:
        return 'github';
      case ThirdPartySignInButtonType.discord:
        return 'discord';
      case ThirdPartySignInButtonType.wechat:
        return 'wechat';
      case ThirdPartySignInButtonType.qq:
        return 'qq';
      case ThirdPartySignInButtonType.tikTok:
        return 'tikTok';
      case ThirdPartySignInButtonType.anonymous:
        throw UnsupportedError('Anonymous session does not have a provider');
    }
  }

  FlowySvgData get icon {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return FlowySvgs.m_apple_icon_xl;
      case ThirdPartySignInButtonType.google:
        return FlowySvgs.m_google_icon_xl;
      case ThirdPartySignInButtonType.github:
        return FlowySvgs.m_github_icon_xl;
      case ThirdPartySignInButtonType.discord:
        return FlowySvgs.m_discord_icon_xl;
      case ThirdPartySignInButtonType.wechat:
        return FlowySvgs.m_wechat_icon_xl;
      case ThirdPartySignInButtonType.qq:
        return FlowySvgs.m_qq_icon_xl;
      case ThirdPartySignInButtonType.tikTok:
        return FlowySvgs.m_tiktok_icon_xl;
      case ThirdPartySignInButtonType.anonymous:
        return FlowySvgs.m_discord_icon_xl;
    }
  }

  String get labelText {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return LocaleKeys.signIn_signInWithApple.tr();
      case ThirdPartySignInButtonType.google:
        return LocaleKeys.signIn_signInWithGoogle.tr();
      case ThirdPartySignInButtonType.github:
        return LocaleKeys.signIn_signInWithGithub.tr();
      case ThirdPartySignInButtonType.discord:
        return LocaleKeys.signIn_signInWithDiscord.tr();
      case ThirdPartySignInButtonType.wechat:
        return '微信登录';
      case ThirdPartySignInButtonType.qq:
        return LocaleKeys.signIn_signInWithQQ.tr();
      case ThirdPartySignInButtonType.tikTok:
        return LocaleKeys.signIn_signInWithTiktok.tr();
      case ThirdPartySignInButtonType.anonymous:
        return 'Anonymous session';
    }
  }

  // https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
  Color backgroundColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return isDarkMode ? Colors.white : Colors.black;
      case ThirdPartySignInButtonType.wechat:
        return const Color(0xFF07C160);
      case ThirdPartySignInButtonType.google:
      case ThirdPartySignInButtonType.github:
      case ThirdPartySignInButtonType.discord:
      case ThirdPartySignInButtonType.anonymous:
      case ThirdPartySignInButtonType.tikTok:
      case ThirdPartySignInButtonType.qq:
        return isDarkMode ? Colors.black : Colors.grey.shade100;
    }
  }

  Color textColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ThirdPartySignInButtonType.apple:
        return isDarkMode ? Colors.black : Colors.white;
      case ThirdPartySignInButtonType.wechat:
        return Colors.white;
      case ThirdPartySignInButtonType.google:
      case ThirdPartySignInButtonType.github:
      case ThirdPartySignInButtonType.discord:
      case ThirdPartySignInButtonType.anonymous:
      case ThirdPartySignInButtonType.tikTok:
      case ThirdPartySignInButtonType.qq:
        return isDarkMode ? Colors.white : Colors.black;
    }
  }

  BlendMode? get blendMode {
    switch (this) {
      case ThirdPartySignInButtonType.apple:
      case ThirdPartySignInButtonType.github:
        return BlendMode.srcIn;
      case ThirdPartySignInButtonType.wechat:
        return null;
      default:
        return null;
    }
  }
}

class MobileThirdPartySignInButton extends StatelessWidget {
  const MobileThirdPartySignInButton({
    super.key,
    this.height = 38,
    this.fontSize = 14.0,
    required this.onTap,
    required this.type,
  });

  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final ThirdPartySignInButtonType type;

  @override
  Widget build(BuildContext context) {
    return AFOutlinedIconTextButton.normal(
      text: type.labelText,
      onTap: onTap,
      size: AFButtonSize.l,
      iconBuilder: (context, isHovering, disabled) {
        return FlowySvg(
          type.icon,
          size: Size.square(16),
          blendMode: type.blendMode,
        );
      },
    );
  }
}

class DesktopThirdPartySignInButton extends StatelessWidget {
  const DesktopThirdPartySignInButton({
    super.key,
    required this.type,
    required this.onTap,
  });

  final ThirdPartySignInButtonType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AFOutlinedIconTextButton.normal(
      text: type.labelText,
      onTap: onTap,
      size: AFButtonSize.l,
      iconBuilder: (context, isHovering, disabled) {
        return FlowySvg(
          type.icon,
          size: Size.square(18),
          blendMode: type.blendMode,
        );
      },
    );
  }
}
