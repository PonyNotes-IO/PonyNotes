import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsLegalDocumentView extends StatelessWidget {
  const SettingsLegalDocumentView({
    super.key,
    required this.title,
    required this.content,
    required this.onBack,
  });

  final String title;
  final String content;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: title,
      autoSeparate: false,
      children: [
        // 返回按钮
        _buildBackButton(context),
        const VSpace(24),
        // 文档内容
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onBack,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.green,
              ),
              const HSpace(4),
              Text(
                "法律条款",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
