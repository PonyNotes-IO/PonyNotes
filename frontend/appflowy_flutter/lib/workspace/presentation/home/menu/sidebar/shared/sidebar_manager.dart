import 'package:flutter/material.dart';

enum SidebarType {
  trash,
}

class SidebarManager extends ChangeNotifier {
  SidebarType? _currentSidebar;
  Widget? _currentSidebarWidget;

  SidebarType? get currentSidebar => _currentSidebar;
  Widget? get currentSidebarWidget => _currentSidebarWidget;

  void showSidebar(SidebarType type, Widget sidebarWidget) {
    print('SidebarManager: 显示侧边栏 - 类型: $type');
    _currentSidebar = type;
    _currentSidebarWidget = sidebarWidget;
    print('SidebarManager: 状态已更新，通知监听器');
    notifyListeners();
  }

  void hideSidebar() {
    _currentSidebar = null;
    _currentSidebarWidget = null;
    notifyListeners();
  }

  bool get isSidebarVisible => _currentSidebar != null;
} 