import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

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
class CalendarMainPanel extends StatefulWidget {
  @override
  State<CalendarMainPanel> createState() => _CalendarMainPanelState();
}

class _CalendarMainPanelState extends State<CalendarMainPanel> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isSidebarExpanded = true;
  final PopoverController _settingsPopoverController = PopoverController();
  List<String> _diaryItems = [
    '小马笔记教程',
    '星月考研笔记汇总', 
    '新东方考研日记',
    '每日读书笔记',
    'OP考研笔记本',
  ];

  void _showAddDiaryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newItemTitle = '';
        return AlertDialog(
          title: Text('添加新日记项'),
          content: TextField(
            onChanged: (value) {
              newItemTitle = value;
            },
            decoration: InputDecoration(
              hintText: '输入日记项标题',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (newItemTitle.isNotEmpty) {
                  setState(() {
                    _diaryItems.add(newItemTitle);
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.settings, size: 20),
            title: Text('日历设置', style: TextStyle(fontSize: 14)),
            onTap: () {
              _settingsPopoverController.close();
              // TODO: 打开日历设置页面
            },
          ),
          ListTile(
            leading: Icon(Icons.import_export, size: 20),
            title: Text('导入/导出', style: TextStyle(fontSize: 14)),
            onTap: () {
              _settingsPopoverController.close();
              // TODO: 打开导入导出功能
            },
          ),
          ListTile(
            leading: Icon(Icons.sync, size: 20),
            title: Text('同步设置', style: TextStyle(fontSize: 14)),
            onTap: () {
              _settingsPopoverController.close();
              // TODO: 打开同步设置
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, size: 20),
            title: Text('关于', style: TextStyle(fontSize: 14)),
            onTap: () {
              _settingsPopoverController.close();
              // TODO: 显示关于信息
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Row(
                  children: [
            // 左侧日历导航区
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: _isSidebarExpanded ? 300 : 60,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  // 顶部工具栏，包含收起/展开按钮和其他操作按钮
                  Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: _isSidebarExpanded 
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                '日历',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // 添加按钮
                            IconButton(
                              icon: Icon(Icons.add, size: 20),
                              onPressed: _showAddDiaryDialog,
                              tooltip: '添加新日记项',
                            ),
                            // 更多选项按钮
                            AppFlowyPopover(
                              controller: _settingsPopoverController,
                              direction: PopoverDirection.bottomWithCenterAligned,
                              child: IconButton(
                                icon: Icon(Icons.more_horiz, size: 20),
                                onPressed: () => _settingsPopoverController.show(),
                                tooltip: '更多选项',
                              ),
                              popupBuilder: (context) => _buildSettingsMenu(),
                            ),
                            // 收起/展开按钮 (使用双箭头图标)
                            IconButton(
                              icon: Icon(Icons.keyboard_double_arrow_left, size: 20),
                              onPressed: () {
                                setState(() {
                                  _isSidebarExpanded = !_isSidebarExpanded;
                                });
                              },
                              tooltip: '收起侧边栏',
                            ),
                          ],
                        )
                      : Center(
                          child: IconButton(
                            icon: Icon(Icons.keyboard_double_arrow_right, size: 20),
                            onPressed: () {
                              setState(() {
                                _isSidebarExpanded = !_isSidebarExpanded;
                              });
                            },
                            tooltip: '展开侧边栏',
                          ),
                        ),
                  ),
                  // 侧边栏内容
                  Expanded(
                    child: _isSidebarExpanded ? _buildExpandedSidebar() : _buildCollapsedSidebar(),
                  ),
                ],
              ),
            ),
                      // 右侧详情区 - 完全铺满剩余空间
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    // 右侧顶部工具栏
                    Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedDay != null 
                              ? DateFormat('yyyy年MM月dd日').format(_selectedDay!)
                              : DateFormat('yyyy年MM月').format(_focusedDay),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          // 视图切换按钮
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(value: 'month', label: Text('月视图')),
                              ButtonSegment(value: 'week', label: Text('周视图')),
                              ButtonSegment(value: 'day', label: Text('日视图')),
                            ],
                            selected: {'month'},
                            onSelectionChanged: (Set<String> selection) {
                              // TODO: 实现视图切换
                            },
                          ),
                        ],
                      ),
                    ),
                    // 主内容区
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '选择左侧日记本查看详情',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (_selectedDay != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '当前选中: ${DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(_selectedDay!)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
          );
    }

  Widget _buildExpandedSidebar() {
    return Column(
      children: [
        // 日历组件 - 固定高度以避免布局错误
        Container(
          height: 280, // 设置固定高度
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: DatePicker(
            isRange: false,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ),
        // 分隔线
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).dividerColor,
        ),
        SizedBox(height: 8),
        // 日记项目列表标题
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '我的日记',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '${_diaryItems.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        // 日记项目列表 - 使用Expanded让其占据剩余空间
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: _diaryItems.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: 1),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Icon(
                    Icons.book_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    _diaryItems[index],
                    style: TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // TODO: 打开对应的日记项目
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedSidebar() {
    return Column(
      children: [
        SizedBox(height: 16),
        // 只显示图标
        IconButton(
          icon: Icon(Icons.calendar_today, size: 24),
          onPressed: () {
            // TODO: 快速导航功能
          },
          tooltip: '日历导航',
        ),
        SizedBox(height: 16),
        // 显示日记项目数量
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_diaryItems.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

}
  
  class CalendarPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}
