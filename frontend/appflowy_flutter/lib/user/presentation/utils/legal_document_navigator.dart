import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/legal_document_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalDocumentNavigator {
  /// 导航到用户协议页面
  static void navigateToUserAgreement(BuildContext context) {
    context.push(
      LegalDocumentScreen.routeName,
      extra: {
        'title': LocaleKeys.signIn_userAgreement.tr(),
        'content': LocaleKeys.signIn_userAgreementContent.tr(),
      },
    );
  }

  /// 导航到隐私政策页面
  static void navigateToPrivacyPolicy(BuildContext context) {
    context.push(
      LegalDocumentScreen.routeName,
      extra: {
        'title': LocaleKeys.signIn_privacyPolicy.tr(),
        'content': LocaleKeys.signIn_privacyPolicyContent.tr(),
      },
    );
  }

  /// 导航到个人信息保护声明页面
  static void navigateToPersonalInfoProtection(BuildContext context) {
    context.push(
      LegalDocumentScreen.routeName,
      extra: {
        'title': LocaleKeys.signIn_personalInfoProtection.tr(),
        'content': LocaleKeys.signIn_personalInfoProtectionContent.tr(),
      },
    );
  }
}
