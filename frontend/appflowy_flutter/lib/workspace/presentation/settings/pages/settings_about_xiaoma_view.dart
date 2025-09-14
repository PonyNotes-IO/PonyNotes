import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
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
  @override
  Widget build(BuildContext context) {
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
            _showSubscriptionDetailsDialog(context);
          },
          child: _buildTextItem(context, "订阅详情", showArrow: true),
        ),
        GestureDetector(
          onTap: () {
            _showLegalTermsDialog(context);
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

  void _showSubscriptionDetailsDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '订阅详情',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.close,
                      color: theme.iconTheme.color,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  color: theme.dividerColor,
                  thickness: 1,
                  height: 16,
                ),
                Text(
                  '支付',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '确认购买后，你的 iTunes 账户将会进行付款。',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '付费账户在当前订购周期结束时将自动续订，你的iTunes 账户会再一次进行付款。同时，你可以在当前付费周期结束前至少 24 个小时取消自动续订。',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '订购后，你随时可以在 AppleID 账户设置中管理或者关闭自动续订。',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLegalTermsDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '法律条款',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.close,
                      color: theme.iconTheme.color,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegalMenuItem(context, '版权声明'),
                _buildLegalMenuItem(context, '服务条款'),
                _buildLegalMenuItem(context, '隐私条款'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegalMenuItem(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withOpacity(0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showCopyrightDialog(BuildContext context) {
    _showDetailDialog(
      context,
      '版权声明',
      '本应用及其内容受版权法保护。未经许可，不得复制、修改、分发或以其他方式使用本应用的任何部分。',
    );
  }

  void _showServiceTermsDialog(BuildContext context) {
    _showDetailDialog(
      context,
      '服务条款',
      '使用本应用即表示您同意遵守我们的服务条款。我们保留随时修改这些条款的权利，修改后的条款将在应用内公布后生效。',
    );
  }

  void _showPrivacyTermsDialog(BuildContext context) {
    _showDetailDialog(
      context,
      '隐私条款',
      '我们重视您的隐私。我们收集的个人信息仅用于改善服务质量，不会与第三方共享您的个人数据，除非法律要求或获得您的明确同意。',
    );
  }

  void _showDetailDialog(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.close,
                      color: theme.iconTheme.color,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  color: theme.dividerColor,
                  thickness: 1,
                  height: 16,
                ),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
