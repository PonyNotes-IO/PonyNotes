import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'sidebar_my_space_menu.dart';

class SidebarMySpaceButton extends StatelessWidget {
  const SidebarMySpaceButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 直接返回我的空间菜单，避免重复的标题
    return const SidebarMySpaceMenu();
  }
}
