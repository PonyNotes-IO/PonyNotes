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
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'presentation/new_event_page.dart';
import 'widgets/schedule_sidebar.dart';

// 添加日历事件类
class CalendarEvent {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAllDay;
  final bool isImportant;
  final bool isRepeat;
  final String calendar;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.isImportant,
    required this.isRepeat,
    required this.calendar,
  });
}

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
  PluginId get id => "CalendarMainStack"; // 使用固定ID，类似问AI的做法
}

class CalendarMainWidgetBuilder extends PluginWidgetBuilder {
  @override
  String? get viewName => '日历'; // 显示标题

  @override
  Widget get leftBarItem => const FlowyText.medium('日历'); // 显示左侧标题

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
    // 直接返回日历面板，避免视图查找错误
    return CalendarMainPanel();
  }
}

// 主日历面板骨架
class CalendarMainPanel extends StatefulWidget {
  @override
  State<CalendarMainPanel> createState() => _CalendarMainPanelState();
}

class _CalendarMainPanelState extends State<CalendarMainPanel> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late int _currentMonthIndex;
  late int _currentYear;
  late List<CalendarEvent> _events;
  late bool _showNewEventPage;
  late Function()? _saveEventCallback;
  late String? _currentViewId; // 添加当前视图ID
  late bool _isSidebarExpanded;
  late PopoverController _settingsPopoverController;
  late PopoverController _addPopoverController;
  late List<String> _diaryItems;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(Duration(days: 365));
    _lastDay = DateTime.now().add(Duration(days: 365));
    _currentMonthIndex = DateTime.now().month;
    _currentYear = DateTime.now().year;
    _events = [];
    _showNewEventPage = false;
    _saveEventCallback = null;
    _currentViewId = null;
    _isSidebarExpanded = true;
    _settingsPopoverController = PopoverController();
    _addPopoverController = PopoverController();
    _diaryItems = [
      '小马笔记教程',
      '星月考研笔记汇总', 
      '新东方考研日记',
      '每日读书笔记',
      'OP考研笔记本',
    ];
    
    // 初始化时尝试创建或获取日历视图
    _initializeCalendarView();
  }

  // 初始化日历视图
  Future<void> _initializeCalendarView() async {
    try {
      // 尝试创建一个新的日历视图
      final result = await ViewBackendService.createView(
        parentViewId: 'workspace', // 使用工作区作为父视图
        name: '日历视图',
        layoutType: ViewLayoutPB.Calendar,
      );
      
      result.fold(
        (view) {
          setState(() {
            _currentViewId = view.id;
          });
          print('成功创建日历视图: ${view.id}');
          
          // 创建成功后，等待一下让数据库初始化完成，然后刷新数据
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {}); // 触发重建以加载真实数据
            }
          });
        },
        (error) {
          print('创建日历视图失败: ${error.msg}');
          // 如果创建失败，尝试使用默认ID
          setState(() {
            _currentViewId = 'default_calendar_view';
          });
        },
      );
    } catch (e) {
      print('初始化日历视图时发生错误: $e');
      // 使用默认ID作为后备
      setState(() {
        _currentViewId = 'default_calendar_view';
      });
    }
  }

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

  void _showCreateScheduleDialog() {
    setState(() {
      _showNewEventPage = true;
    });
  }

  void _hideNewEventPage() {
    setState(() {
      _showNewEventPage = false;
    });
  }

  void _onEventCreated(Map<String, dynamic> eventData) {
    // TODO: 保存日程到数据库或状态管理
    // 创建日程逻辑将在后续实现
    
    final description = eventData['description'] as String;
    final isAllDay = eventData['isAllDay'] as bool;
    final startTime = eventData['startTime'] as TimeOfDay;
    final endTime = eventData['endTime'] as TimeOfDay;
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('日程创建成功: $description'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 隐藏新建日程界面
    _hideNewEventPage();
  }

  Widget _buildAddMenu() {
    return Container(
      width: 140,
      padding: EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              _addPopoverController.close();
              _showAddDiaryDialog();
            },
            child: Container(
              height: 38,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.book, size: 18),
                  SizedBox(width: 8),
                  Text('新建日记页', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              _addPopoverController.close();
              _showCreateScheduleDialog();
            },
            child: Container(
              height: 38,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.event, size: 18),
                  SizedBox(width: 8),
                  Text('新建日程', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      width: 350,
      padding: EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '日历显示设置',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // 订阅系统日历
          InkWell(
            onTap: () {
              _settingsPopoverController.close();
              // TODO: 切换订阅系统日历
            },
            child: Container(
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('订阅系统日历', style: TextStyle(fontSize: 14)),
                  Spacer(),
                  Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: EdgeInsets.only(right: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 日记模式
          InkWell(
            onTap: () {
              _settingsPopoverController.close();
              // TODO: 切换日记模式
            },
            child: Container(
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 18),
                  SizedBox(width: 10),
                  Text('日记模式', style: TextStyle(fontSize: 14)),
                  Spacer(),
                  Text(
                    '默认',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              clipBehavior: Clip.hardEdge,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                maxWidth: _isSidebarExpanded ? 300 : 60,
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
                    child: ClipRect(
                      child: _isSidebarExpanded 
                        ? Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    '日历',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // 添加按钮
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: AppFlowyPopover(
                                  controller: _addPopoverController,
                                  direction: PopoverDirection.bottomWithCenterAligned,
                                  child: IconButton(
                                    icon: Icon(Icons.add, size: 18),
                                    onPressed: () => _addPopoverController.show(),
                                    tooltip: '添加新内容',
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints.tightFor(width: 32, height: 32),
                                  ),
                                  popupBuilder: (context) => _buildAddMenu(),
                                ),
                              ),
                              SizedBox(width: 4),
                              // 更多选项按钮
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: AppFlowyPopover(
                                  controller: _settingsPopoverController,
                                  direction: PopoverDirection.bottomWithCenterAligned,
                                  child: IconButton(
                                    icon: Icon(Icons.more_horiz, size: 18),
                                    onPressed: () => _settingsPopoverController.show(),
                                    tooltip: '更多选项',
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints.tightFor(width: 32, height: 32),
                                  ),
                                  popupBuilder: (context) => _buildSettingsMenu(),
                                ),
                              ),
                              SizedBox(width: 4),
                              // 收起/展开按钮 (使用双箭头图标)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  icon: Icon(Icons.keyboard_double_arrow_left, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _isSidebarExpanded = !_isSidebarExpanded;
                                    });
                                  },
                                  tooltip: '收起侧边栏',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints.tightFor(width: 32, height: 32),
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                          )
                        : Center(
                            child: IconButton(
                              icon: Icon(Icons.keyboard_double_arrow_right, size: 22),
                              onPressed: () {
                                setState(() {
                                  _isSidebarExpanded = !_isSidebarExpanded;
                                });
                              },
                              tooltip: '展开侧边栏',
                            ),
                          ),
                    ),
                  ),
                  // 右侧工具栏 - 已移除三个按钮
                  // 侧边栏内容
                  Expanded(
                    child: _isSidebarExpanded ? _buildExpandedSidebar() : _buildCollapsedSidebar(),
                  ),
                ],
                ),
              ),
            ),
            // 右侧详情区 - 完全铺满剩余空间
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: _showNewEventPage 
                  ? _buildNewEventView()
                  : _buildDefaultView(),
              ),
            ),
        ],
      ),
          );
    }

  Widget _buildExpandedSidebar() {
    return Column(
      children: [
        // 日历组件 - 使用紧凑的固定高度
        Container(
          height: 280, // 紧凑的固定高度，减少留白
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ClipRect(
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
        ),
        // 分隔线
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).dividerColor,
        ),
        SizedBox(height: 8),
        // 统一的日记和日程展示组件 - 使用Expanded让其占据剩余空间
        Expanded(
          child: CalendarContent(
            diaryItems: _diaryItems,
            selectedDate: _selectedDay ?? _focusedDay,
            viewId: _currentViewId, // 传递视图ID
          ),
        ),
      ],
    );
  }

    Widget _buildCollapsedSidebar() {
    return const SizedBox.shrink();
  }

  Widget _buildDefaultView() {
    return Center(
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
                '当前选中: ${_selectedDay!.year}年${_selectedDay!.month}月${_selectedDay!.day}日',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewEventView() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 新建日程顶部工具栏
          Container(
            height: 56,
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
                Expanded(
                  child: Text(
                    '新建日程',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 取消按钮
                TextButton(
                  onPressed: _hideNewEventPage,
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // 保存按钮
                ElevatedButton(
                  onPressed: () {
                    // 调用保存回调函数
                    if (_saveEventCallback != null && _saveEventCallback!()) {
                      _hideNewEventPage();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    '保存',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // 新建日程内容
          Expanded(
            child: NewEventPage(
              selectedDate: _selectedDay ?? _focusedDay,
              onEventCreated: _onEventCreated,
              onCancel: _hideNewEventPage,
              onSaveRequested: (saveCallback) {
                _saveEventCallback = saveCallback;
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 统一的日记和日程展示组件
class CalendarContent extends StatelessWidget {
  final List<String> diaryItems;
  final DateTime selectedDate;
  final String? viewId;

  const CalendarContent({
    Key? key,
    required this.diaryItems,
    required this.selectedDate,
    this.viewId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动态日期标题 - 根据选中的日期显示
          Text(
            '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 日记内容
          if (diaryItems.isNotEmpty) ...[
            ...diaryItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          // 日程集成部分
          if (viewId != null) ...[
            Expanded(
              child: ScheduleSidebar(
                databaseViewId: viewId,
              ),
            ),
          ] else ...[
            Text(
              '暂无日程数据',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CalendarPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}
