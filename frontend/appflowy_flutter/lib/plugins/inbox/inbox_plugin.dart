import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/presentation/inbox_page.dart';

class InboxPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return InboxPlugin();
  }

  @override
  String get menuName => "收件箱";

  @override
  FlowySvgData get icon => FlowySvgs.icon_inbox_s;

  @override
  PluginType get pluginType => PluginType.inbox;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

class InboxPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class InboxPlugin extends Plugin {
  @override
  PluginWidgetBuilder get widgetBuilder => InboxPluginWidgetBuilder();

  @override
  PluginId get id => "inbox";

  @override
  PluginType get pluginType => PluginType.inbox;
}

class InboxPluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  @override
  String? get viewName => null; // 移除标题栏显示的"收件箱"

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  Widget get leftBarItem => const SizedBox.shrink();

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) {
    return const Text('收件箱');
  }

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    return const InboxPage();
  }
}
