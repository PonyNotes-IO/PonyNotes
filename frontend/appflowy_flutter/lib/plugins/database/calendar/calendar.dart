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
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:nanoid/nanoid.dart';
import 'presentation/new_event_page.dart';
import 'presentation/edit_event_page.dart';
import 'widgets/schedule_sidebar.dart';
import 'models/schedule_model.dart';
import 'dart:ui' as ui;
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';

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
  late bool _showEditEventPage; // 显示编辑日程页面
  late ScheduleItem? _editingSchedule; // 正在编辑的日程
  late Function()? _saveEventCallback;
  late String? _currentViewId; // 添加当前视图ID
  late bool _isSidebarExpanded;
  late PopoverController _settingsPopoverController;
  late PopoverController _addPopoverController;
  late ViewPB? _selectedNote; // 添加选中的笔记


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
    _showEditEventPage = false;
    _editingSchedule = null;
    _saveEventCallback = null;
    _currentViewId = null;
    _isSidebarExpanded = true;
    _settingsPopoverController = PopoverController();
    _addPopoverController = PopoverController();
    _selectedNote = null;

    
    // 初始化时尝试创建或获取日历视图
    _initializeCalendarView();
  }

  // 初始化日历视图
  Future<void> _initializeCalendarView() async {
    try {
      // 使用与ScheduleModel相同的固定ViewId
      final String fixedViewId = fixedUuid(12345, UuidType.privateSpace); // 使用与ScheduleModel相同的固定ID
      
      // 先检查视图是否已存在
      final result = await ViewBackendService.getView(fixedViewId);
      
      await result.fold(
        (view) async {
          // 视图已存在，直接使用
          setState(() {
            _currentViewId = view.id;
          });
  
        },
        (error) async {
          // 视图不存在，创建新视图
          
          final createResult = await ViewBackendService.createOrphanView(
            viewId: fixedViewId,
            name: '日历视图',
            layoutType: ViewLayoutPB.Calendar,
          );
          
          createResult.fold(
            (view) {
              setState(() {
                _currentViewId = view.id;
              });
            },
            (createError) {
              // 如果创建失败，使用固定ID作为后备
              setState(() {
                _currentViewId = fixedViewId;
              });
            },
          );
        },
      );
      
      // 初始化完成后，等待一下让数据库初始化完成，然后刷新数据
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {}); // 触发重建以加载真实数据
        }
      });
      
    } catch (e) {
      // 使用固定ID作为后备
      setState(() {
        _currentViewId = fixedUuid(12345, UuidType.privateSpace);
      });
    }
  }



  void _showCreateDocumentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String documentTitle = '';
        return AlertDialog(
          title: Text('新建日记页'),
          content: TextField(
            onChanged: (value) {
              documentTitle = value;
            },
            decoration: InputDecoration(
              hintText: '输入日记标题',
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
              onPressed: () async {
                if (documentTitle.isNotEmpty) {
                  try {
                    // 创建新的文档
                    final result = await ViewBackendService.createOrphanView(
                      viewId: nanoid(),
                      name: documentTitle,
                      layoutType: ViewLayoutPB.Document,
                    );
                    
                    result.fold(
                      (view) {
                        // 创建成功后打开新文档
                        context.read<TabsBloc>().add(
                          TabsEvent.openTab(plugin: view.plugin(), view: view),
                        );
                      },
                      (error) {
                        // 处理错误
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('创建文档失败: ${error.msg}')),
                        );
                      },
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('创建文档失败: $e')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text('创建'),
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

  // 处理点击日程
  void _onScheduleTap(ScheduleItem schedule) {
    setState(() {
      _showEditEventPage = true;
      _editingSchedule = schedule;
      _showNewEventPage = false; // 确保新建页面关闭
      _selectedNote = null; // 清除选中的笔记
    });
  }

  // 处理点击笔记
  void _onNoteTap(ViewPB note) {
    setState(() {
      _selectedNote = note;
      _showNewEventPage = false;
      _showEditEventPage = false;
    });
  }

  void _hideEditEventPage() {
    setState(() {
      _showEditEventPage = false;
      _editingSchedule = null;
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

  void _onEventUpdated(Map<String, dynamic> eventData) {
    final description = eventData['description'] as String;
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('日程更新成功: $description'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 隐藏编辑日程界面
    _hideEditEventPage();
  }

  void _onEventDeleted(String scheduleId) {
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('日程已删除'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 隐藏编辑日程界面
    _hideEditEventPage();
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
              _showCreateDocumentDialog();
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
                  : _showEditEventPage && _editingSchedule != null
                    ? _buildEditEventView()
                    : _selectedNote != null
                      ? _buildNoteContentView()
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // 确保内容与侧边栏边缘有距离
            child: CalendarContent(
              selectedDate: _selectedDay ?? _focusedDay,
              viewId: _currentViewId, // 传递视图ID
              onScheduleTap: _onScheduleTap, // 传递点击回调
              onNoteTap: _onNoteTap, // 传递笔记点击回调
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildCollapsedSidebar() {
    return const SizedBox.shrink();
  }

  Widget _buildDefaultView() {
    return Container();
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

  Widget _buildEditEventView() {
    if (_editingSchedule == null) return _buildDefaultView();
    
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 编辑日程顶部工具栏
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
                    '编辑日程',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 取消按钮
                TextButton(
                  onPressed: _hideEditEventPage,
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
                      _hideEditEventPage();
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
          // 编辑日程内容
          Expanded(
            child: EditEventPage(
              schedule: _editingSchedule!,
              onEventUpdated: _onEventUpdated,
              onEventDeleted: _onEventDeleted,
              onCancel: _hideEditEventPage,
              onSaveRequested: (saveCallback) {
                _saveEventCallback = saveCallback;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteContentView() {
    if (_selectedNote == null) {
      return _buildDefaultView();
    }

    // 直接显示笔记内容，类似回收站的做法
    return CalendarDocumentView(view: _selectedNote!);
  }
}

// 统一的日记和日程展示组件
class CalendarContent extends StatefulWidget {
  final DateTime selectedDate;
  final String? viewId;
  final Function(ScheduleItem)? onScheduleTap; // 点击日程的回调
  final Function(ViewPB)? onNoteTap; // 点击笔记的回调

  const CalendarContent({
    Key? key,
    required this.selectedDate,
    this.viewId,
    this.onScheduleTap,
    this.onNoteTap,
  }) : super(key: key);

  @override
  State<CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  List<ViewPB> _realNotes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotesForDate();
  }

  @override
  void didUpdateWidget(CalendarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadNotesForDate();
    }
  }

  Future<void> _loadNotesForDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取所有视图
      final allViewsResult = await ViewBackendService.getAllViews();
      
      await allViewsResult.fold(
        (allViews) async {
          // 过滤出文档类型的视图（笔记），只包含有父页面的文档（排除根级页面如Workspace）
          final documentViews = allViews.items
              .where((view) => 
                view.layout == ViewLayoutPB.Document && 
                view.parentViewId.isNotEmpty)
              .toList();

          // 根据选中日期过滤笔记
          final selectedDateStart = DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
          );
          final selectedDateEnd = selectedDateStart.add(Duration(days: 1));

          // 过滤当天创建的笔记
          final notesForDate = documentViews.where((view) {
            final createTime = DateTime.fromMillisecondsSinceEpoch(
              view.createTime.toInt() * 1000,
            );
            return createTime.isAfter(selectedDateStart) && 
                   createTime.isBefore(selectedDateEnd);
          }).toList();

          setState(() {
            _realNotes = notesForDate;
            _isLoading = false;
          });
        },
        (error) {
          setState(() {
            _realNotes = [];
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _realNotes = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动态日期标题 - 根据选中的日期显示
          Text(
            '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 显示加载状态
          if (_isLoading) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ]
          // 真实的笔记内容
          else if (_realNotes.isNotEmpty) ...[
            ...(_realNotes.map((note) => _buildNoteItem(note))),
            const SizedBox(height: 16),
          ]
          // 如果当天没有笔记，显示提示
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '当天暂无笔记',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
          
          // 日程集成部分
          if (widget.viewId != null) ...[
            ScheduleSidebarContent(
              databaseViewId: widget.viewId,
              onScheduleTap: widget.onScheduleTap,
            ),
          ],
          // 移除else部分，不显示"暂无日程数据"提示
        ],
      ),
    );
  }

  Widget _buildNoteItem(ViewPB note) {
    return FlowyHover(
      style: HoverStyle(hoverColor: Theme.of(context).colorScheme.secondary),
      builder: (_, onHover) => GestureDetector(
        onTap: () {
          // 点击笔记时调用回调函数
          if (widget.onNoteTap != null) {
            widget.onNoteTap!(note);
          }
        },
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatCreateTime(note.createTime.toInt()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreateTime(int timestamp) {
    final createTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createDate = DateTime(createTime.year, createTime.month, createTime.day);
    
    if (createDate == today) {
      return '${createTime.hour.toString().padLeft(2, '0')}:${createTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${createTime.month}/${createTime.day}';
    }
  }
}

class CalendarPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

// 日历文档视图组件 - 参考回收站的实现
class CalendarDocumentView extends StatefulWidget {
  const CalendarDocumentView({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<CalendarDocumentView> createState() => _CalendarDocumentViewState();
}

class _CalendarDocumentViewState extends State<CalendarDocumentView> {
  late DocumentBloc _documentBloc;
  late ViewBloc _viewBloc;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
  }

  @override
  void didUpdateWidget(CalendarDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当view改变时，重新初始化blocs
    if (oldWidget.view.id != widget.view.id) {
      _disposeBlocs();
      _initializeBlocs();
    }
  }

  void _initializeBlocs() {
    _documentBloc = DocumentBloc(documentId: widget.view.id)
      ..add(const DocumentEvent.initial());
    _viewBloc = ViewBloc(view: widget.view)
      ..add(const ViewEvent.initial());
  }

  void _disposeBlocs() {
    _documentBloc.close();
    _viewBloc.close();
  }

  @override
  void dispose() {
    _disposeBlocs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _documentBloc),
        BlocProvider.value(value: _viewBloc),
      ],
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          final editorState = state.editorState;
          final error = state.error;
          if (error != null || editorState == null) {
            return _buildErrorView(context, error);
          }

          return _buildDocumentView(context, editorState);
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, FlowyError? error) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '无法加载文档内容',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此文档可能已被删除或损坏',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '错误信息: ${error.msg}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentView(BuildContext context, EditorState editorState) {
    // 检查文档是否为空或只有空内容
    final hasContent = editorState.document.root.children.any((node) {
      final text = node.delta?.toPlainText() ?? '';
      return text.trim().isNotEmpty;
    });
    
    // 设置编辑器为只读状态
    editorState.editable = false;
    
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Expanded(
          child: _buildAppFlowyEditor(context, editorState),
        ),
      ],
    );
  }

  Widget _buildAppFlowyEditor(BuildContext context, EditorState editorState) {
    final isRTL = context.read<AppearanceSettingsCubit>().state.layoutDirection ==
        LayoutDirection.rtlLayout;
    final textDirection = isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: AppFlowyEditorPage(
        editorState: editorState,
        autoFocus: false,
        useViewInfoBloc: false,
        styleCustomizer: EditorStyleCustomizer(
          context: context,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          editorState: editorState,
        ),
        placeholderText: (node) {
          // 为空的段落节点提供占位符文本
          if (node.type == ParagraphBlockKeys.type && 
              (node.delta?.toPlainText() ?? '').trim().isEmpty) {
            return '此文档暂无内容，点击编辑按钮开始添加内容';
          }
          return '';
        },
      ),
    );
  }



  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            widget.view.name.isEmpty ? '无标题笔记' : widget.view.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 创建时间
          Text(
            '创建时间：${_formatCreateTime(widget.view.createTime.toInt())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}
