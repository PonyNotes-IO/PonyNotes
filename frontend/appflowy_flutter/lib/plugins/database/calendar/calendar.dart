import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';

class CalendarPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return DatabaseTabBarViewPlugin(pluginType: pluginType, view: data);
    } else {
      // 支持无data时返回主日历页面
      return CalendarMainPlugin();
    }
  }

  @override
  String get menuName => LocaleKeys.calendar_menuName.tr();

  @override
  FlowySvgData get icon => FlowySvgs.icon_calendar_s;

  @override
  PluginType get pluginType => PluginType.calendar;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Calendar;
}

// 新增主日历插件
class CalendarMainPlugin extends Plugin {
  @override
  PluginType get pluginType => PluginType.calendar;

  @override
  PluginWidgetBuilder get widgetBuilder => CalendarMainWidgetBuilder();

  @override
  PluginId get id => "CalendarMainStack";
}

class CalendarMainWidgetBuilder extends PluginWidgetBuilder {
  @override
  String? get viewName => null; // 去除标题

  @override
  Widget get leftBarItem => const SizedBox.shrink(); // 去除左侧标题

  @override
  Widget? get rightBarItem => null;

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) =>
      const SizedBox.shrink();

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
    return CalendarMainPanel();
  }
}

// 主日历面板骨架
class CalendarMainPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Row(
        children: [
          // 左侧日历导航区
          Container(
            width: 300,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                // 复用DatePicker组件
                SizedBox(
                  height: 320,
                  child: DatePicker(
                    isRange: false,
                    focusedDay: today,
                    selectedDay: today,
                    onDaySelected: (selected, focused) {},
                  ),
                ),
                // 日记本/日程树
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                          title: Text('小马笔记教程',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      ListTile(title: Text('星月考研笔记汇总')),
                      ListTile(title: Text('新东方考研日记')),
                      ListTile(title: Text('每日读书笔记')),
                      ListTile(title: Text('OP考研笔记本')),
                      ListTile(
                          title: Text('添加日记项',
                              style: TextStyle(color: Colors.blue))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右侧详情区 - 完全铺满剩余空间
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[50],
              child: Center(
                child: Text('请选择日记本或日程，右侧显示详情'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}
