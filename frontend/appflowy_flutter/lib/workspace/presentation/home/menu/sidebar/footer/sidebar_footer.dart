import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/footer/sidebar_toast.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'sidebar_footer_button.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (FeatureFlag.planBilling.isOn)
          BillingGateGuard(
            builder: (context) {
              return const SidebarToast();
            },
          ),
        // 移除了模板按钮的Row
      ],
    );
  }
}

// 保留SidebarTemplateButton类定义，以防其他地方还需要使用
class SidebarTemplateButton extends StatelessWidget {
  const SidebarTemplateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SidebarFooterButton(
      leftIconSize: const Size.square(16.0),
      leftIcon: const FlowySvg(
        FlowySvgs.icon_template_s,
      ),
      text: LocaleKeys.template_label.tr(),
      onTap: () => afLaunchUrlString('https://appflowy.com/templates'),
    );
  }
}

class SidebarWidgetButton extends StatelessWidget {
  const SidebarWidgetButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: const FlowySvg(FlowySvgs.sidebar_footer_widget_s),
      ),
    );
  }
}
