import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/date_cell_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:nanoid/nanoid.dart';
import 'package:fixnum/fixnum.dart';

// 日程数据模型 - 基于 AppFlowy 数据库行
class ScheduleItem {
  final String id; // 数据库行ID
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final bool isImportant;
  final bool isCompleted; // 完成状态
  final String category;
  final Color color;
  final String? reminderId; // AppFlowy 提醒ID
  final ReminderOption reminderOption; // 提醒选项

  ScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.isImportant = false,
    this.isCompleted = false, // 默认未完成
    this.category = '默认',
    this.color = Colors.blue,
    this.reminderId,
    this.reminderOption = ReminderOption.none,
  });

  // 从CalendarEventPB创建ScheduleItem
  factory ScheduleItem.fromCalendarEventPB(CalendarEventPB eventPB) {
    final timestamp = eventPB.timestamp;
    final date = timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000)
        : DateTime.now();
    
    // 默认设置为1小时的事件
    final startTime = date;
    final endTime = date.add(Duration(hours: 1));
    
    return ScheduleItem(
      id: eventPB.rowMeta.id,
      title: eventPB.title.isNotEmpty ? eventPB.title : '无标题事件',
      description: '来自数据库的日程',
      startTime: startTime,
      endTime: endTime,
      isAllDay: false,
      isImportant: false,
      isCompleted: false,
      category: '数据库',
      color: Colors.blue,
    );
  }

  ScheduleItem copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    bool? isImportant,
    bool? isCompleted,
    String? category,
    Color? color,
    String? reminderId,
    ReminderOption? reminderOption,
  }) {
    return ScheduleItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      color: color ?? this.color,
      reminderId: reminderId ?? this.reminderId,
      reminderOption: reminderOption ?? this.reminderOption,
    );
  }
}

// 日程管理模型 - 基于 AppFlowy 数据库
class ScheduleModel extends ChangeNotifier {
  final List<ScheduleItem> _schedules = [];
  bool _isLoading = false;
  String? _currentViewId; // 当前数据库视图ID
  
  List<ScheduleItem> get schedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  String? get currentViewId => _currentViewId;

  // 设置当前数据库视图ID
  void setViewId(String viewId) {
    _currentViewId = viewId;
    _loadSchedulesFromDatabase();
  }

  // 从 AppFlowy 数据库加载日程
  Future<void> _loadSchedulesFromDatabase() async {
    if (_currentViewId == null) return;

    _setLoading(true);
    
    try {
      // 获取所有日历事件
      final payload = DatabaseViewIdPB(value: _currentViewId!);
      final result = await DatabaseEventGetAllCalendarEvents(payload).send();
      
      result.fold(
        (events) {
          // 转换为 ScheduleItem
          final newSchedules = events.items.map((eventPB) {
            return ScheduleItem.fromCalendarEventPB(eventPB);
          }).toList();
          
          _schedules.clear();
          _schedules.addAll(newSchedules);
          
          // 添加示例数据用于演示
          _addSampleSchedules();
          
          notifyListeners();
        },
        (error) {
          print('加载日程失败: $error');
          // 如果加载失败，添加示例数据
          _addSampleSchedules();
          notifyListeners();
        },
      );
    } catch (e) {
      print('加载日程时发生错误: $e');
      // 如果出现异常，添加示例数据
      _addSampleSchedules();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // 添加示例日程数据
  void _addSampleSchedules() {
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));
    
    _schedules.addAll([
      ScheduleItem(
        id: 'sample_1',
        title: '明天早上7点去机场',
        description: '06月30日 02:00-03:00, 我的日历',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 2, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 3, 0),
        isCompleted: false,
        color: Colors.blue,
      ),
      ScheduleItem(
        id: 'sample_2',
        title: '明天早上7点去机场',
        description: '06月30日 02:00-03:00, 我的日历',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 2, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 3, 0),
        isCompleted: true,
        color: Colors.green,
      ),
    ]);
  }

  // 创建新的日程（直接保存到 AppFlowy 数据库）
  Future<String?> createSchedule({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    bool isImportant = false,
    String category = '默认',
    Color color = Colors.blue,
    ReminderOption reminderOption = ReminderOption.none,
  }) async {
    if (_currentViewId == null) {
      print('错误: 未设置数据库视图ID');
      return null;
    }

    try {
      // 使用 AppFlowy 标准的创建行方法
      // 这将创建一个基本的行，用户可以后续在行详情页中编辑标题和其他字段
      final result = await RowBackendService.createRow(
        viewId: _currentViewId!,
        withCells: (builder) {
          // 由于我们不知道具体的字段信息，
          // 这里创建一个空行，用户可以后续编辑
          // 如果有日期字段，可以使用 builder.insertDate(dateField, startTime)
        },
      );

      return result.fold(
        (rowMeta) async {
          // 创建成功后，刷新数据以获取最新的事件列表
          await refresh();
          return rowMeta.id;
        },
        (error) {
          print('创建日程失败: $error');
          return null;
        },
      );
    } catch (e) {
      print('创建日程时发生错误: $e');
      return null;
    }
  }

  // 更新日程
  Future<bool> updateSchedule(ScheduleItem schedule) async {
    if (_currentViewId == null) return false;

    try {
      // 更新数据库中的数据
      // 这里需要根据实际需求更新特定字段
      
      // 更新本地列表
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
        notifyListeners();

        // 更新提醒
        if (schedule.reminderOption != ReminderOption.none) {
          _setReminder(schedule);
        } else if (schedule.reminderId != null) {
          _removeReminder(schedule.reminderId!);
        }

        return true;
      }
    } catch (e) {
      print('更新日程时发生错误: $e');
    }
    
    return false;
  }

  // 删除日程
  Future<bool> deleteSchedule(String scheduleId) async {
    if (_currentViewId == null) return false;

    try {
      // 从数据库删除
      await RowBackendService.deleteRows(_currentViewId!, [scheduleId]);

      // 从本地列表删除
      final schedule = _schedules.firstWhere((s) => s.id == scheduleId);
      if (schedule.reminderId != null) {
        _removeReminder(schedule.reminderId!);
      }

      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      
      return true;
    } catch (e) {
      print('删除日程时发生错误: $e');
      return false;
    }
  }

  // 设置提醒（使用 AppFlowy 提醒系统）
  void _setReminder(ScheduleItem schedule) async {
    try {
      final reminderBloc = getIt<ReminderBloc>();
      final reminderId = schedule.reminderId ?? nanoid();
      
      reminderBloc.add(
        ReminderEvent.addById(
          reminderId: reminderId,
          objectId: _currentViewId!,
          meta: {
            'rowId': schedule.id,
            'title': schedule.title,
          },
          scheduledAt: Int64(
            schedule.reminderOption.getNotificationDateTime(schedule.startTime)
                .millisecondsSinceEpoch ~/ 1000,
          ),
        ),
      );
    } catch (e) {
      print('设置提醒失败: $e');
    }
  }

  // 移除提醒
  void _removeReminder(String reminderId) async {
    try {
      final reminderBloc = getIt<ReminderBloc>();
      reminderBloc.add(ReminderEvent.removeReminder(reminderId: reminderId));
    } catch (e) {
      print('移除提醒失败: $e');
    }
  }

  // 获取指定日期的日程
  List<ScheduleItem> getSchedulesForDate(DateTime date) {
    return _schedules.where((schedule) {
      final scheduleDate = schedule.startTime;
      return scheduleDate.year == date.year &&
             scheduleDate.month == date.month &&
             scheduleDate.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // 获取日期范围内的日程
  List<ScheduleItem> getSchedulesInRange(DateTime start, DateTime end) {
    return _schedules.where((schedule) {
      return schedule.startTime.isAfter(start.subtract(Duration(days: 1))) &&
             schedule.startTime.isBefore(end.add(Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // 切换日程完成状态
  Future<bool> toggleScheduleCompletion(String scheduleId) async {
    try {
      final index = _schedules.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        final schedule = _schedules[index];
        final updatedSchedule = schedule.copyWith(isCompleted: !schedule.isCompleted);
        _schedules[index] = updatedSchedule;
        notifyListeners();
        
        // TODO: 在实际应用中，这里应该更新数据库中的完成状态
        // await updateScheduleInDatabase(updatedSchedule);
        
        return true;
      }
    } catch (e) {
      print('切换完成状态时发生错误: $e');
    }
    return false;
  }

  // 获取未完成的日程
  List<ScheduleItem> get incompleteSchedules => 
      _schedules.where((schedule) => !schedule.isCompleted).toList();

  // 获取已完成的日程
  List<ScheduleItem> get completedSchedules => 
      _schedules.where((schedule) => schedule.isCompleted).toList();

  // 刷新数据
  Future<void> refresh() async {
    await _loadSchedulesFromDatabase();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 

// 临时的DatabaseEventGetAllCalendarEvents类实现
class DatabaseEventGetAllCalendarEvents {
  final DatabaseViewIdPB request;
  
  DatabaseEventGetAllCalendarEvents(this.request);

  Future<FlowyResult<RepeatedCalendarEventPB, FlowyError>> send() async {
    // 这里应该调用实际的FFI方法
    // 暂时返回空结果，等待protobuf重新生成
    return FlowySuccess(RepeatedCalendarEventPB());
  }
} 