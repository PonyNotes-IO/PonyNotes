import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_bloc.dart';

// 日程数据模型
class ScheduleItem {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final bool isImportant;
  final String category;
  final Color color;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.isImportant = false,
    this.category = '默认',
    this.color = Colors.blue,
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
      category: '数据库',
      color: Colors.blue,
    );
  }

  // 判断是否已完成（当前时间超过结束时间）
  bool get isCompleted => DateTime.now().isAfter(endTime);

  // 判断是否正在进行中
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // 判断是否即将开始（未来1小时内）
  bool get isUpcoming {
    final now = DateTime.now();
    final oneHourLater = now.add(Duration(hours: 1));
    return startTime.isAfter(now) && startTime.isBefore(oneHourLater);
  }

  // 格式化时间显示
  String get timeText {
    if (isAllDay) {
      return '全天';
    }
    final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startTimeStr - $endTimeStr';
  }

  // 状态文本
  String get statusText {
    if (isCompleted) return '已完成';
    if (isOngoing) return '进行中';
    if (isUpcoming) return '即将开始';
    return '未开始';
  }

  // 状态颜色
  Color get statusColor {
    if (isCompleted) return Colors.grey;
    if (isOngoing) return Colors.green;
    if (isUpcoming) return Colors.orange;
    return Colors.blue;
  }

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    bool? isImportant,
    String? category,
    Color? color,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isImportant: isImportant ?? this.isImportant,
      category: category ?? this.category,
      color: color ?? this.color,
    );
  }
}

// 日程管理器
class ScheduleManager extends ChangeNotifier {
  static final ScheduleManager _instance = ScheduleManager._internal();
  factory ScheduleManager() => _instance;
  ScheduleManager._internal() {
    // 默认使用独立模式，初始化示例数据
    _isIndependentMode = true;
    _initializeWithSampleData();
  }

  final List<ScheduleItem> _schedules = [];
  String? _currentViewId;
  bool _isLoading = false;
  bool _isIndependentMode = true; // 新增：独立模式标志

  List<ScheduleItem> get schedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  bool get isIndependentMode => _isIndependentMode;

  // 设置当前视图ID（用于数据库集成模式）
  void setViewId(String viewId) {
    _currentViewId = viewId;
    if (viewId.isNotEmpty) {
      _isIndependentMode = false; // 切换到数据库集成模式
      _loadRealEvents();
    } else {
      _isIndependentMode = true; // 切换到独立模式
      _initializeWithSampleData(); // 使用示例数据
    }
  }

  // 从真实数据库加载事件（仅在数据库集成模式下使用）
  Future<void> _loadRealEvents() async {
    if (_isIndependentMode || _currentViewId == null || _currentViewId!.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 创建请求参数
      final payload = DatabaseViewIdPB(value: _currentViewId!);
      
      // 调用数据库事件获取所有日历事件
      final result = await DatabaseEventGetAllCalendarEvents(payload).send();
      
      result.fold(
        (events) {
          // 转换CalendarEventPB为ScheduleItem
          final newSchedules = events.items.map((eventPB) {
            return ScheduleItem.fromCalendarEventPB(eventPB);
          }).toList();
          
          // 更新日程列表
          _schedules.clear();
          _schedules.addAll(newSchedules);
          
          print('成功加载 ${_schedules.length} 个真实日程事件');
          notifyListeners();
        },
        (error) {
          print('加载真实日程失败: $error');
          // 如果加载失败，使用示例数据作为后备
          _initializeWithSampleData();
        },
      );
    } catch (e) {
      print('加载真实日程时发生错误: $e');
      // 使用示例数据作为后备
      _initializeWithSampleData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 刷新事件数据
  Future<void> refreshEvents() async {
    if (_isIndependentMode) {
      // 独立模式下不需要刷新，数据在内存中
      return;
    }
    await _loadRealEvents();
  }

  // 获取今日日程
  List<ScheduleItem> get todaySchedules {
    final today = DateTime.now();
    return _schedules.where((schedule) {
      return _isSameDay(schedule.startTime, today) ||
             _isSameDay(schedule.endTime, today) ||
             (schedule.startTime.isBefore(today) && schedule.endTime.isAfter(today));
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // 获取未完成的日程
  List<ScheduleItem> get incompleteSchedules {
    return _schedules.where((schedule) => !schedule.isCompleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // 获取已完成的日程
  List<ScheduleItem> get completedSchedules {
    return _schedules.where((schedule) => schedule.isCompleted).toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // 添加日程
  void addSchedule(ScheduleItem schedule) {
    _schedules.add(schedule);
    
    // 在独立模式下，保存到本地存储
    if (_isIndependentMode) {
      _saveToLocalStorage();
    }
    
    notifyListeners();
  }

  // 删除日程
  void removeSchedule(String id) {
    _schedules.removeWhere((schedule) => schedule.id == id);
    
    // 在独立模式下，保存到本地存储
    if (_isIndependentMode) {
      _saveToLocalStorage();
    }
    
    notifyListeners();
  }

  // 更新日程
  void updateSchedule(ScheduleItem updatedSchedule) {
    final index = _schedules.indexWhere((schedule) => schedule.id == updatedSchedule.id);
    if (index != -1) {
      _schedules[index] = updatedSchedule;
      
      // 在独立模式下，保存到本地存储
      if (_isIndependentMode) {
        _saveToLocalStorage();
      }
      
      notifyListeners();
    }
  }

  // 保存到本地存储（独立模式）
  void _saveToLocalStorage() {
    // TODO: 实现本地存储逻辑，可以使用SharedPreferences或Hive
    // 暂时只打印日志
    print('保存 ${_schedules.length} 个日程到本地存储');
  }

  // 从本地存储加载（独立模式）
  void _loadFromLocalStorage() {
    // TODO: 实现从本地存储加载逻辑
    // 暂时使用示例数据
    _initializeWithSampleData();
  }

  // 设置加载状态
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // 生成唯一ID
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // 初始化一些示例数据（作为后备）
  void _initializeWithSampleData() {
    final now = DateTime.now();
    
    _schedules.clear();
    _schedules.addAll([
      ScheduleItem(
        id: _generateUniqueId(),
        title: '团队会议',
        description: '讨论项目进度和下周计划',
        startTime: now.add(Duration(hours: 1)),
        endTime: now.add(Duration(hours: 2)),
        isImportant: true,
        category: '工作',
        color: Colors.blue,
      ),
      ScheduleItem(
        id: _generateUniqueId(),
        title: '健身训练',
        description: '有氧运动30分钟 + 力量训练',
        startTime: now.subtract(Duration(hours: 1)),
        endTime: now.add(Duration(minutes: 30)),
        category: '健康',
        color: Colors.green,
      ),
      ScheduleItem(
        id: _generateUniqueId(),
        title: '阅读时间',
        description: '《深度工作》第3章',
        startTime: now.subtract(Duration(hours: 2)),
        endTime: now.subtract(Duration(hours: 1)),
        category: '学习',
        color: Colors.purple,
      ),
      ScheduleItem(
        id: _generateUniqueId(),
        title: '项目复盘',
        description: '总结本周工作得失',
        startTime: now.add(Duration(days: 1, hours: 9)),
        endTime: now.add(Duration(days: 1, hours: 10)),
        isImportant: true,
        category: '工作',
        color: Colors.red,
      ),
    ]);
    notifyListeners();
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