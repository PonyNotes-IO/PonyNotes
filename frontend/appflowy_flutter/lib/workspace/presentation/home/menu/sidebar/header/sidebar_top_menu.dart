import 'dart:io' show Platform;

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

/// Sidebar top menu is the top bar of the sidebar.
///
/// in the top menu, we have:
///   - appflowy icon (Windows or Linux)
///   - close / expand sidebar button
class SidebarTopMenu extends StatelessWidget {
  const SidebarTopMenu({
    super.key,
    required this.isSidebarOnHover,
  });

  final ValueNotifier<bool> isSidebarOnHover;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
      builder: (context, _) => SizedBox(
        height: !UniversalPlatform.isWindows ? HomeSizes.topBarHeight : 45,
        child: MoveWindowDetector(
          child: Row(
            children: [
              _buildLogoIcon(context),
              const Spacer(),
              _buildCollapseMenuButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoIcon(BuildContext context) {
    // 隐藏logo
    return const SizedBox.shrink();
  }

  Widget _buildCollapseMenuButton(BuildContext context) {
    // 隐藏折叠按钮
    return const SizedBox.shrink();
  }
}
