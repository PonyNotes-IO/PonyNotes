import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_legal_terms_view.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
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
        // 功能列表 - 使用文本样式
        GestureDetector(
          onTap: () {
            // TODO: 处理订阅详情点击
          },
          child: _buildTextItem(context, "订阅详情", showArrow: true),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentPage = 'legal';
            });
          },
          child: _buildTextItem(context, "法律条款", showArrow: true),
        ),
        GestureDetector(
          onTap: () {
            // TODO: 处理版本更新点击
          },
          child: _buildTextItem(context, "版本更新", showArrow: false, subtitle: "V${ApplicationInfo.applicationVersion}"),
        ),
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

  Widget _buildTextItem(
    BuildContext context,
    String title, {
    bool showArrow = false,
    String subtitle = '',
  }) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              title,
              fontSize: 16,
              color: theme.textColorScheme.primary,
            ),
          ),
          if (subtitle.isNotEmpty)
            FlowyText(
              subtitle,
              fontSize: 14,
              color: theme.textColorScheme.secondary,
            ),
          if (showArrow)
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}
