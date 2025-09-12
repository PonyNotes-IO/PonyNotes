import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({
    super.key,
    required this.changeSelectedPage,
    required this.currentPage,
    required this.userProfile,
    required this.isBillingEnabled,
    required this.currentUserRole,
  });

  final Function changeSelectedPage;
  final SettingsPage currentPage;
  final UserProfilePB userProfile;
  final bool isBillingEnabled;
  final AFRolePB? currentUserRole;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainerColorScheme.layer01,
        borderRadius: BorderRadiusDirectional.horizontal(
          start: Radius.circular(theme.spacing.m),
        ),
      ),
      height: double.infinity,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 24,
          horizontal: theme.spacing.l,
        ),
        physics: const ClampingScrollPhysics(),
        child: Column(
          spacing: theme.spacing.xs,
          children: [
            // User info card section at the top
            _buildUserInfoCard(context),
            const VSpace(16),
            SettingsMenuElement(
              page: SettingsPage.accountManagement,
              selectedPage: currentPage,
              label: LocaleKeys.settings_accountPage_menuLabel.tr(),
              icon: const FlowySvg(FlowySvgs.settings_page_user_m),
              changeSelectedPage: changeSelectedPage,
            ),
            SettingsMenuElement(
              page: SettingsPage.workspace,
              selectedPage: currentPage,
              label: "通用设置",
              icon: const FlowySvg(FlowySvgs.settings_page_workspace_m),
              changeSelectedPage: changeSelectedPage,
            ),
            if (FeatureFlag.membersSettings.isOn &&
                userProfile.workspaceType == WorkspaceTypePB.ServerW &&
                currentUserRole != null &&
                currentUserRole != AFRolePB.Guest)
              SettingsMenuElement(
                page: SettingsPage.member,
                selectedPage: currentPage,
                label: LocaleKeys.settings_appearance_members_label.tr(),
                icon: const FlowySvg(FlowySvgs.settings_page_users_m),
                changeSelectedPage: changeSelectedPage,
              ),
            SettingsMenuElement(
              page: SettingsPage.manageData,
              selectedPage: currentPage,
              label: LocaleKeys.settings_manageDataPage_menuLabel.tr(),
              icon: const FlowySvg(FlowySvgs.settings_page_database_m),
              changeSelectedPage: changeSelectedPage,
            ),
            SettingsMenuElement(
              page: SettingsPage.storage,
              selectedPage: currentPage,
              label: "存储设置",
              icon: const Icon(Icons.storage_outlined, size: 20),
              changeSelectedPage: changeSelectedPage,
            ),
            SettingsMenuElement(
              page: SettingsPage.notifications,
              selectedPage: currentPage,
              label: LocaleKeys.settings_menu_notifications.tr(),
              icon: const FlowySvg(FlowySvgs.settings_page_bell_m),
              changeSelectedPage: changeSelectedPage,
            ),
            SettingsMenuElement(
              page: SettingsPage.cloud,
              selectedPage: currentPage,
              label: LocaleKeys.settings_menu_cloudSettings.tr(),
              icon: const FlowySvg(FlowySvgs.settings_page_cloud_m),
              changeSelectedPage: changeSelectedPage,
            ),
            SettingsMenuElement(
              page: SettingsPage.shortcuts,
              selectedPage: currentPage,
              label: LocaleKeys.settings_shortcutsPage_menuLabel.tr(),
              icon: const FlowySvg(FlowySvgs.settings_page_keyboard_m),
              changeSelectedPage: changeSelectedPage,
            ),
            SettingsMenuElement(
              page: SettingsPage.ai,
              selectedPage: currentPage,
              label: LocaleKeys.settings_aiPage_menuLabel.tr(),
              icon: const FlowySvg(
                FlowySvgs.settings_page_ai_m,
              ),
              changeSelectedPage: changeSelectedPage,
            ),
            if (userProfile.workspaceType == WorkspaceTypePB.ServerW &&
                currentUserRole != null &&
                currentUserRole != AFRolePB.Guest)
              SettingsMenuElement(
                page: SettingsPage.sites,
                selectedPage: currentPage,
                label: LocaleKeys.settings_sites_title.tr(),
                icon: const FlowySvg(FlowySvgs.settings_page_earth_m),
                changeSelectedPage: changeSelectedPage,
              ),
            if (FeatureFlag.planBilling.isOn && isBillingEnabled) ...[
              SettingsMenuElement(
                page: SettingsPage.plan,
                selectedPage: currentPage,
                label: LocaleKeys.settings_planPage_menuLabel.tr(),
                icon: const FlowySvg(FlowySvgs.settings_page_plan_m),
                changeSelectedPage: changeSelectedPage,
              ),
              SettingsMenuElement(
                page: SettingsPage.billing,
                selectedPage: currentPage,
                label: LocaleKeys.settings_billingPage_menuLabel.tr(),
                icon: const FlowySvg(FlowySvgs.settings_page_credit_card_m),
                changeSelectedPage: changeSelectedPage,
              ),
            ],
            if (kDebugMode)
              SettingsMenuElement(
                // no need to translate this page
                page: SettingsPage.featureFlags,
                selectedPage: currentPage,
                label: 'Feature Flags',
                icon: const Icon(
                  Icons.flag,
                  size: 20,
                ),
                changeSelectedPage: changeSelectedPage,
              ),
            // 关于小马按钮
            SettingsMenuElement(
              page: SettingsPage.aboutXiaoma,
              selectedPage: currentPage,
              label: LocaleKeys.legal_aboutXiaoma.tr(),
              icon: const Icon(
                Icons.info_outline,
                size: 20,
              ),
              changeSelectedPage: changeSelectedPage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return GestureDetector(
      onTap: () => changeSelectedPage(SettingsPage.account),
            child: Container(
        padding: EdgeInsets.all(theme.spacing.m),
        decoration: BoxDecoration(
          color: theme.surfaceContainerColorScheme.layer01,
          borderRadius: BorderRadius.circular(theme.spacing.m),
          border: Border.all(
            color: theme.borderColorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 账号标题
          FlowyText(
            '账号',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColorScheme.primary,
          ),
          const VSpace(16),
          // 用户信息行
          Row(
            children: [
              // 用户头像
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5A3C),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const HSpace(12),
              // 用户名和账户类型
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlowyText(
                      '小马笔记的笔记',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColorScheme.primary,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const VSpace(4),
                    FlowyText(
                      '免费账户',
                      fontSize: 14,
                      color: theme.textColorScheme.secondary,
                    ),
                  ],
                ),
              ),
              // 升级按钮
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B47),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FlowyText(
                  '升级',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const VSpace(20),
                     // 权益图标行
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _buildBenefitIcon(context, const Color(0xFFFF9F7A), '权益一'),
               _buildBenefitIcon(context, const Color(0xFF7FD4A3), '权益二'),
               _buildBenefitIcon(context, const Color(0xFF7AB8FF), '权益三'),
               _buildBenefitIcon(context, const Color(0xFFE07AFF), '权益四'),
               _buildBenefitIcon(context, const Color(0xFFFF7AB8), '权益五'),
             ],
           ),
        ],
      ),
    ),
    );
  }

  Widget _buildBenefitIcon(BuildContext context, Color color, String label) {
    final theme = AppFlowyTheme.of(context);
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.star,
            color: Colors.white,
            size: 24,
          ),
        ),
        const VSpace(8),
        FlowyText(
          label,
          fontSize: 12,
          color: theme.textColorScheme.secondary,
        ),
      ],
    );
  }
}

class SimpleSettingsMenu extends StatelessWidget {
  const SimpleSettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8) +
                const EdgeInsets.only(left: 8, right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              // Right padding is added to make the scrollbar centered
              // in the space between the menu and the content
              padding: const EdgeInsets.only(right: 4) +
                  const EdgeInsets.symmetric(vertical: 16),
              physics: const ClampingScrollPhysics(),
              child: SeparatedColumn(
                separatorBuilder: () => const VSpace(16),
                children: [
                  SettingsMenuElement(
                    page: SettingsPage.cloud,
                    selectedPage: SettingsPage.cloud,
                    label: LocaleKeys.settings_menu_cloudSettings.tr(),
                    icon: const Icon(Icons.sync),
                    changeSelectedPage: () {},
                  ),
                  if (kDebugMode)
                    SettingsMenuElement(
                      // no need to translate this page
                      page: SettingsPage.featureFlags,
                      selectedPage: SettingsPage.cloud,
                      label: 'Feature Flags',
                      icon: const Icon(Icons.flag),
                      changeSelectedPage: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
