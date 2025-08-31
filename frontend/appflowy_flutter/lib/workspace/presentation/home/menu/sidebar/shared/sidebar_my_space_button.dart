import 'package:flutter/material.dart';
import 'sidebar_my_space_menu.dart';

class SidebarMySpaceButton extends StatelessWidget {
  const SidebarMySpaceButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 直接返回我的空间菜单，避免重复的标题
    return const SidebarMySpaceMenu();
  }
}
