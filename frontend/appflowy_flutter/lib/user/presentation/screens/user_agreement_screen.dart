import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  static const routeName = '/UserAgreementScreen';

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.signIn_userAgreement.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          LocaleKeys.signIn_userAgreementContent.tr(),
          style: theme.textStyle.body.standard(),
        ),
      ),
    );
  }
}
