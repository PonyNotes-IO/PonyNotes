import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

class SettingsAccountContactSection extends StatelessWidget {
  const SettingsAccountContactSection({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    // 判断是邮箱登录还是手机号登录
    final bool isEmailLogin = userProfile.email.isNotEmpty;
    final bool isPhoneLogin = userProfile.phoneNumber.isNotEmpty;
    
    String title;
    String contactInfo;
    
    if (isEmailLogin) {
      title = LocaleKeys.settings_accountPage_email_title.tr();
      contactInfo = userProfile.email;
    } else if (isPhoneLogin) {
      title = LocaleKeys.settings_accountPage_phone_title.tr();
      contactInfo = userProfile.phoneNumber;
    } else {
      // 如果都为空，显示邮箱标题但内容为空
      title = LocaleKeys.settings_accountPage_email_title.tr();
      contactInfo = '';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textStyle.body.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        VSpace(theme.spacing.s),
        Text(
          contactInfo,
          style: theme.textStyle.caption.standard(
            color: theme.textColorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
