import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  static const routeName = '/LegalDocumentScreen';

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              hoverColor: Colors.grey.withOpacity(0.1),
              splashColor: Colors.grey.withOpacity(0.2),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
        ),
      ),
    );
  }
}
