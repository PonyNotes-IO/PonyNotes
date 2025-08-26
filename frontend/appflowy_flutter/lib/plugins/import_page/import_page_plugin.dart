import 'package:flutter/material.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'import_page_screen.dart';

// Simplified import page plugin for basic functionality
class ImportPagePlugin {
  static Widget buildScreen() {
    return const ImportPageScreen();
  }
  
  static String get pluginName => "导入页面";
  static String get pluginId => "import_page";
}

class ImportPagePluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return ImportPagePluginImpl();
  }

  @override
  String get menuName => "导入页面";

  @override
  FlowySvgData get icon => FlowySvgs.import_s;

  @override
  PluginType get pluginType => PluginType.importPage;

  @override
  ViewLayoutPB? get layoutType => null;
}

class ImportPagePluginImpl extends Plugin {
  @override
  String get id => "import_page";

  @override
  PluginWidgetBuilder get widgetBuilder => ImportPagePluginWidgetBuilder();

  @override
  PluginType get pluginType => PluginType.importPage;
}

class ImportPagePluginWidgetBuilder extends PluginWidgetBuilder {
  @override
  String? get viewName => "导入页面";

  @override
  Widget get leftBarItem => const Text('导入页面');

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) => leftBarItem;

  @override
  Widget? get rightBarItem => null;

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    return const ImportPageScreen();
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  NavigationCallback get action => (id) {};
}


