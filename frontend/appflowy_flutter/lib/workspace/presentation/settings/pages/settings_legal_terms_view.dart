import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_legal_document_view.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsLegalTermsView extends StatefulWidget {
  const SettingsLegalTermsView({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<SettingsLegalTermsView> createState() => _SettingsLegalTermsViewState();
}

class _SettingsLegalTermsViewState extends State<SettingsLegalTermsView> {
  String? _currentDocumentTitle;
  String? _currentDocumentContent;

  @override
  Widget build(BuildContext context) {
    // 如果正在显示具体文档，显示文档视图
    if (_currentDocumentTitle != null && _currentDocumentContent != null) {
      return SettingsLegalDocumentView(
        title: _currentDocumentTitle!,
        content: _currentDocumentContent!,
        onBack: () {
          setState(() {
            _currentDocumentTitle = null;
            _currentDocumentContent = null;
          });
        },
      );
    }

    // 否则显示法律条款列表
    return SettingsBody(
      title: LocaleKeys.legal_legalTerms.tr(),
      autoSeparate: false,
      children: [
        // 返回按钮
        _buildBackButton(context),
        const VSpace(24),
        // 法律条款列表
        _buildLegalTermItem(context, LocaleKeys.legal_copyrightStatement.tr(),
            () {
          setState(() {
            _currentDocumentTitle = LocaleKeys.legal_copyrightStatement.tr();
            _currentDocumentContent =
                LocaleKeys.legal_copyrightStatementContent.tr();
          });
        }),
        const VSpace(8),
        _buildLegalTermItem(context, LocaleKeys.legal_serviceTerms.tr(), () {
          setState(() {
            _currentDocumentTitle = LocaleKeys.legal_serviceTerms.tr();
            _currentDocumentContent = LocaleKeys.legal_serviceTermsContent.tr();
          });
        }),
        const VSpace(8),
        _buildLegalTermItem(context, LocaleKeys.legal_privacyPolicy.tr(), () {
          setState(() {
            _currentDocumentTitle = LocaleKeys.legal_privacyPolicy.tr();
            _currentDocumentContent =
                LocaleKeys.legal_privacyPolicyContent.tr();
          });
        }),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: widget.onBack,
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
                LocaleKeys.legal_aboutXiaoma.tr(),
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

  Widget _buildLegalTermItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
