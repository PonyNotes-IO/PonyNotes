import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_legal_terms_view.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

class SettingsAboutXiaomaView extends StatefulWidget {
  const SettingsAboutXiaomaView({super.key});

  @override
  State<SettingsAboutXiaomaView> createState() =>
      _SettingsAboutXiaomaViewState();
}

class _SettingsAboutXiaomaViewState extends State<SettingsAboutXiaomaView> {
  String? _currentPage;

  @override
  Widget build(BuildContext context) {
    // 如果在显示法律条款页面，显示该页面
    if (_currentPage == 'legal') {
      return SettingsLegalTermsView(
        onBack: () {
          setState(() {
            _currentPage = null;
          });
        },
      );
    }

    // 否则显示关于小马页面
    return SettingsBody(
      title: LocaleKeys.legal_aboutXiaoma.tr(),
      autoSeparate: false,
      children: [
        // 小马笔记品牌信息
        _buildBrandInfo(context),
        const SettingsCategorySpacer(),
        // 简化的列表项
        _buildListItem(context, "订阅详情", Icons.star_outline, () {
          // TODO: 处理订阅详情点击
        }),
        const VSpace(8),
        _buildListItem(context, "法律条款", Icons.description_outlined, () {
          setState(() {
            _currentPage = 'legal';
          });
        }),
        const VSpace(8),
        _buildListItem(context, "版本更新", Icons.system_update_outlined, () {
          // TODO: 处理版本更新点击
        }),
      ],
    );
  }

  Widget _buildBrandInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const VSpace(16),
          // 应用名称
          Text(
            "小马笔记",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String title,
    IconData icon,
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
            Icon(
              icon,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const HSpace(12),
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
