import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// Renders a simple header for the settings view
///
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    this.description,
    this.descriptionBuilder,
  });

  final String title;
  final String? description;
  final WidgetBuilder? descriptionBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textStyle.heading2.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        // 移除了所有描述相关的代码，只保留标题
      ],
    );
  }
}
