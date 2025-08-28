import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'new_event_page.dart';

class NewEventPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return NewEventPlugin(selectedDate: data?['selectedDate'] ?? DateTime.now());
  }

  @override
  String get menuName => LocaleKeys.calendar_newEventButtonTooltip.tr();

  @override
  FlowySvgData get icon => FlowySvgs.icon_calendar_s;

  @override
  PluginType get pluginType => PluginType.newEvent;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

class NewEventPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class NewEventPlugin extends Plugin {
  final DateTime selectedDate;

  NewEventPlugin({required this.selectedDate});

  @override
  PluginWidgetBuilder get widgetBuilder => NewEventPluginWidgetBuilder(selectedDate: selectedDate);

  @override
  PluginId get id => "newEvent_${selectedDate.millisecondsSinceEpoch}";

  @override
  PluginType get pluginType => PluginType.newEvent;
}

class NewEventPluginWidgetBuilder extends PluginWidgetBuilder with NavigationItem {
  final DateTime selectedDate;

  NewEventPluginWidgetBuilder({required this.selectedDate});

  @override
  String? get viewName => LocaleKeys.calendar_newEventButtonTooltip.tr();

  @override
  Widget get leftBarItem => Container();

  @override
  Widget? get rightBarItem => null;

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) => leftBarItem;

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    return NewEventPage(
      selectedDate: selectedDate,
      onEventCreated: (Map<String, dynamic> eventData) {
        // 处理事件创建逻辑

      },
      onCancel: () {
        // 处理取消逻辑
      },
    );
  }
} 