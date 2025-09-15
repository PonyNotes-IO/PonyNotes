import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/plugins/inbox/presentation/inbox_main_panel.dart';

class InboxPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    // 支持无data时返回主收件箱页面
    return InboxMainPlugin();
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

// 新增主收件箱插件
class InboxMainPlugin extends Plugin {
  @override
  PluginType get pluginType => PluginType.inbox;

  @override
  PluginWidgetBuilder get widgetBuilder => InboxMainWidgetBuilder();

  @override
  PluginId get id => "InboxMainStack"; // 使用固定ID，类似回收站的做法
}

class InboxMainWidgetBuilder extends PluginWidgetBuilder {
  @override
  String? get viewName => '收件箱'; // 显示标题

  @override
  Widget get leftBarItem => const SizedBox.shrink(); // 不显示左侧标题

  @override
  Widget? get rightBarItem => null;

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) =>
      leftBarItem; // 显示标签栏标题

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  EdgeInsets get contentPadding => EdgeInsets.zero; // 去除所有留白

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    // 不依赖context.userProfile，避免触发GET_VIEW_PB查询
    // 直接返回收件箱面板，避免视图查找错误
    return InboxMainPanel();
  }
}

class InboxPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}
