import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/date_cell_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:nanoid/nanoid.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/uuid.dart';

// 日程数据模型 - 基于 AppFlowy 数据库行
class ScheduleItem {
  final String id; // 数据库行ID
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final bool isImportant;
  final String category;
  final Color color;
  final String? reminderId; // AppFlowy 提醒ID
  final ReminderOption reminderOption; // 提醒选项
  final DateTime? dueDate; // 截止日期

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
    this.reminderId,
    this.reminderOption = ReminderOption.none,
    this.dueDate,
  });

  // 根据当前时间自动判断是否完成
  bool get isCompleted {
    final now = DateTime.now();
    return now.isAfter(endTime);
  }

  // 从CalendarEventPB创建ScheduleItem
  factory ScheduleItem.fromCalendarEventPB(CalendarEventPB eventPB) {
    final timestamp = eventPB.timestamp;
    final endTimestamp = eventPB.endTimestamp;
    
    DateTime startTime;
    DateTime endTime;
    
    if (timestamp != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
      
      if (endTimestamp != null) {
        // 如果有结束时间戳，使用它
        endTime = DateTime.fromMillisecondsSinceEpoch(endTimestamp.toInt() * 1000);
      } else {
        // 如果没有结束时间戳，默认设置为开始时间后1小时
        endTime = startTime.add(Duration(hours: 1));
      }
    } else {
      // 如果没有开始时间戳，使用当前时间
      startTime = DateTime.now();
      endTime = startTime.add(Duration(hours: 1));
    }
    
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
      dueDate: endTime, // 使用结束时间作为截止日期
    );
  }

  ScheduleItem copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    bool? isImportant,
    String? category,
    Color? color,
    String? reminderId,
    ReminderOption? reminderOption,
    DateTime? dueDate,
  }) {
    return ScheduleItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isImportant: isImportant ?? this.isImportant,
      category: category ?? this.category,
      color: color ?? this.color,
      reminderId: reminderId ?? this.reminderId,
      reminderOption: reminderOption ?? this.reminderOption,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

// 日程管理模型 - 基于 AppFlowy 数据库
class ScheduleModel extends ChangeNotifier {
  final List<ScheduleItem> _schedules = [];
  String? _selectedScheduleId; // 当前选中的日程ID
  bool _isLoading = false;
  bool _isDisposed = false; // 跟踪对象是否已被销毁
  String? _currentViewId; // 当前使用的视图ID
  DatabaseController? _databaseController; // 数据库控制器
  DatabaseCallbacks? _databaseCallbacks; // 数据库回调
  
  List<ScheduleItem> get schedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  
  // 获取当前选中的日程ID
  String? get selectedScheduleId => _selectedScheduleId;
  
  // 检查指定日程是否被选中
  bool isScheduleSelected(String scheduleId) => _selectedScheduleId == scheduleId;
  
  // 设置选中的日程
  void selectSchedule(String? scheduleId) {
    if (_selectedScheduleId != scheduleId) {
      _selectedScheduleId = scheduleId;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
  
  // 获取当前视图ID
  String? get currentViewId => _currentViewId;
  
  // 设置视图ID
  void setViewId(String viewId) {
    print('🔧 ScheduleModel 设置 ViewID: $viewId');
    _currentViewId = viewId;
    notifyListeners();
    // 初始化数据库监听器
    _initializeDatabaseListener(viewId);
    // 设置新视图ID后刷新数据
    refresh();
  }

  // 刷新日程数据
  Future<void> refresh() async {
    print('📝 开始刷新日程数据，当前ViewID: $_currentViewId');
    await _loadSchedulesFromDatabase();
    print('✅ 日程数据刷新完成，共加载 ${_schedules.length} 个日程');
  }



  // 从 AppFlowy 数据库加载日程
  Future<void> _loadSchedulesFromDatabase() async {
    _setLoading(true);
    
    try {
      // 使用当前视图ID，如果没有设置则使用默认的新建日程视图ID
      final viewId = _currentViewId ?? _newScheduleViewId;
      // 获取所有日历事件
      final payload = CalendarEventRequestPB.create()..viewId = viewId;
      final result = await DatabaseEventGetAllCalendarEvents(payload).send();
      
      result.fold(
        (events) {
          // 转换为 ScheduleItem
          final newSchedules = events.items.map((eventPB) {
            return ScheduleItem.fromCalendarEventPB(eventPB);
          }).toList();
          
          _schedules.clear();
          _schedules.addAll(newSchedules);
          
          if (!_isDisposed) {
            notifyListeners();
          }
        },
        (error) {
          print('加载日程失败: $error');
          // 如果加载失败，清空列表
          _schedules.clear();
          if (!_isDisposed) {
            notifyListeners();
          }
        },
      );
    } catch (e) {
      print('加载日程时发生错误: $e');
      // 如果出现异常，清空列表
      _schedules.clear();
      if (!_isDisposed) {
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  // 添加示例日程数据
  void _addSampleSchedules() {
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));
    final yesterday = now.subtract(Duration(days: 1));
    
    _schedules.addAll([
      ScheduleItem(
        id: 'sample_1',
        title: '明天早上去机场',
        description: '${tomorrow.month}月${tomorrow.day}日 02:00-03:00, 我的日历',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 2, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 3, 0),
        color: Colors.blue,
        dueDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 3, 0),
      ),
      ScheduleItem(
        id: 'sample_2',
        title: '昨天的会议',
        description: '${yesterday.month}月${yesterday.day}日 02:00-03:00, 我的日历',
        startTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 2, 0),
        endTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 3, 0),
        color: Colors.green,
        dueDate: DateTime(yesterday.year, yesterday.month, yesterday.day, 3, 0),
      ),
    ]);
  }

  // 固定的日历视图ID，专门用于独立的新建日程功能
  // 使用fixedUuid确保每次运行都生成相同的UUID，避免与随机生成的UUID冲突
  static final String _newScheduleViewId = fixedUuid(12345, UuidType.privateSpace);
  
  // 初始化独立的日历视图
  Future<bool> initializeCalendarView() async {
    print('开始初始化独立日历视图...');
    
    try {
      // 先检查视图是否已存在
      final result = await ViewBackendService.getView(_newScheduleViewId);
      
      return result.fold(
        (view) {
          // 视图已存在，直接返回成功
          print('日历视图已存在，跳过创建');
          _currentViewId = _newScheduleViewId; // 设置当前视图ID
          notifyListeners();
          return true;
        },
        (error) async {
          // 视图不存在，需要创建新视图
          print('视图不存在，开始创建新的日历视图...');
          
          final createResult = await ViewBackendService.createOrphanView(
            viewId: _newScheduleViewId,
            name: '新建日程日历',
            layoutType: ViewLayoutPB.Calendar,
          );
          
          return createResult.fold(
            (view) {
              print('日历视图创建成功: ${view.id}');
              _currentViewId = _newScheduleViewId; // 设置当前视图ID
              notifyListeners();
              return true;
            },
            (createError) {
              print('创建日历视图失败: $createError');
              return false;
            },
          );
        },
      );
    } catch (e) {
      print('初始化日历视图时发生异常: $e');
      return false;
    }
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
    DateTime? dueDate,
  }) async {
    print('ScheduleModel.createSchedule 开始执行');
    print('参数: title=$title, description=$description, startTime=$startTime, endTime=$endTime');
    
    // 使用当前视图ID，如果没有设置则使用默认的新建日程视图ID
    final viewId = _currentViewId ?? _newScheduleViewId;
    print('使用视图ID: $viewId');
    
    try {
      // 确保数据库控制器已初始化
      if (_databaseController == null) {
        print('⚠️ 数据库控制器未初始化，尝试初始化...');
        try {
          await _initializeDatabaseListener(viewId);
        } catch (e) {
          print('❌ 数据库监听器初始化失败: $e');
          throw Exception('数据库监听器初始化失败: $e');
        }
        
        if (_databaseController == null) {
          print('❌ 数据库控制器初始化失败');
          throw Exception('数据库控制器初始化失败');
        }
      }
      
      print('开始调用 AppFlowy 数据库 API...');
      
      // 获取数据库字段信息
      final databaseController = _databaseController!;
      print('✅ 数据库控制器已准备就绪');
      
      final fieldController = databaseController.fieldController;
      if (fieldController == null) {
        print('❌ 字段控制器为空');
        throw Exception('字段控制器未初始化');
      }
      
      final fieldInfos = fieldController.fieldInfos;
      if (fieldInfos.isEmpty) {
        print('⚠️ 没有可用的字段');
        throw Exception('数据库中没有可用的字段');
      }
      
      print('可用字段数量: ${fieldInfos.length}');
      for (var field in fieldInfos) {
        print('字段: ${field.name} (${field.fieldType}) - Primary: ${field.isPrimary}');
      }
      
      // 使用 AppFlowy 标准的创建行方法
      final result = await RowBackendService.createRow(
        viewId: viewId,
        withCells: (builder) {
          print('构建数据库行的单元格数据...');
          
          // 查找主字段（通常是标题字段）
          final primaryField = fieldInfos.firstWhere(
            (field) => field.isPrimary,
            orElse: () => fieldInfos.first,
          );
          
          if (primaryField == null) {
            print('❌ 无法找到主字段');
            throw Exception('无法找到主字段');
          }
          
          // 设置标题
          if (primaryField.fieldType == FieldType.RichText) {
            builder.insertText(primaryField, title);
            print('设置标题字段: ${primaryField.name} = $title');
          } else {
            print('⚠️ 主字段不是文本类型，尝试设置到第一个文本字段');
            // 尝试找到第一个文本字段
            final textField = fieldInfos.firstWhere(
              (field) => field.fieldType == FieldType.RichText,
              orElse: () => primaryField,
            );
            builder.insertText(textField, title);
            print('设置标题到字段: ${textField.name} = $title');
          }
          
          // 查找并设置日期时间字段
          for (var field in fieldInfos) {
            print('处理字段: ${field.name} (${field.fieldType})');
            
            if (field.fieldType == FieldType.DateTime) {
              // 根据字段名称判断是开始时间还是结束时间
              final fieldName = field.name.toLowerCase();
              if (fieldName.contains('start') || fieldName.contains('开始') || fieldName.contains('begin')) {
                // 开始时间字段
                builder.insertDate(field, startTime);
                print('设置开始时间字段: ${field.name} = $startTime');
              } else if (fieldName.contains('end') || fieldName.contains('结束') || fieldName.contains('finish')) {
                // 结束时间字段
                builder.insertDate(field, endTime);
                print('设置结束时间字段: ${field.name} = $title');
              } else {
                // 其他日期时间字段（如 Date 字段）
                // 对于单个日期时间字段，我们先设置开始时间
                // 然后在创建行成功后，使用 DateCellBackendService 设置结束时间
                builder.insertDate(field, startTime);
                print('设置日期时间字段: ${field.name} = $startTime (开始时间)');
              }
            } else if (field.fieldType == FieldType.RichText && field.name.toLowerCase().contains('description')) {
              // 描述字段
              builder.insertText(field, description);
              print('设置描述字段: ${field.name} = $description');
            } else if (field.fieldType == FieldType.Checkbox) {
              // 复选框字段 - 暂时跳过，因为 RowDataBuilder 不支持直接设置复选框值
              if (field.name.toLowerCase().contains('all') || field.name.toLowerCase().contains('全天')) {
                print('⚠️ 跳过 Checkbox 字段: ${field.name}，RowDataBuilder 不支持直接设置复选框值');
              } else if (field.name.toLowerCase().contains('important') || field.name.toLowerCase().contains('重要')) {
                print('⚠️ 跳过 Checkbox 字段: ${field.name}，RowDataBuilder 不支持直接设置复选框值');
              }
            } else if (field.fieldType == FieldType.SingleSelect) {
              // 单选字段 - 暂时跳过，因为 RowDataBuilder 不支持直接设置选项
              if (field.name.toLowerCase().contains('category') || field.name.toLowerCase().contains('分类')) {
                print('⚠️ 跳过 SingleSelect 字段: ${field.name}，RowDataBuilder 不支持直接设置选项');
              }
            } else if (field.fieldType == FieldType.MultiSelect) {
              // 多选字段 - 暂时跳过，因为 RowDataBuilder 不支持直接设置选项
              if (field.name.toLowerCase().contains('tag') || field.name.toLowerCase().contains('标签')) {
                print('⚠️ 跳过 MultiSelect 字段: ${field.name}，RowDataBuilder 不支持直接设置选项');
              }
            }
          }
          
          print('单元格数据构建完成');
        },
      );

      print('数据库 API 调用完成，处理结果...');

      return result.fold(
        (rowMeta) async {
          print('数据库行创建成功，行ID: ${rowMeta.id}');
          
          // 现在需要设置结束时间到日期字段
          // 查找日期时间字段
          final dateField = fieldInfos.where(
            (field) => field.fieldType == FieldType.DateTime,
          ).firstOrNull;
          
          if (dateField != null) {
            try {
              print('设置结束时间到日期字段: ${dateField.name}');
              // 使用 DateCellBackendService 设置结束时间
              final dateService = DateCellBackendService(
                viewId: viewId,
                fieldId: dateField.field.id,
                rowId: rowMeta.id,
              );
              
              final updateResult = await dateService.update(
                date: startTime,
                endDate: endTime,
                isRange: true, // 设置为时间范围
              );
              
              updateResult.fold(
                (_) => print('✅ 结束时间设置成功'),
                (error) => print('⚠️ 设置结束时间失败: $error'),
              );
            } catch (e) {
              print('⚠️ 设置结束时间时发生错误: $e');
            }
          }
          
          // 创建对应的本地 ScheduleItem
          final newSchedule = ScheduleItem(
            id: rowMeta.id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            isAllDay: isAllDay,
            isImportant: isImportant,
            category: category,
            color: color,
            reminderOption: reminderOption,
            dueDate: dueDate ?? endTime, // 如果没有指定截止日期，使用结束时间
          );
          
          // 添加到本地列表
          _schedules.add(newSchedule);
          
          // 检查对象是否已被销毁，避免在 dispose 后调用 notifyListeners
          if (!_isDisposed) {
            notifyListeners();
          }
          
          print('本地日程列表已更新，当前日程数量: ${_schedules.length}');
          
          // 创建成功后，刷新数据以获取最新的事件列表
          try {
            print('刷新数据库数据...');
            await refresh();
            print('数据刷新完成');
          } catch (refreshError) {
            print('数据刷新失败，但创建操作已成功: $refreshError');
          }
          
          return rowMeta.id;
        },
        (error) {
          print('创建数据库行失败: ${error.toString()}');
          print('错误代码: ${error.code}');
          print('错误消息: ${error.msg}');
          
          // 抛出异常而不是创建本地示例
          throw Exception('创建日程失败: ${error.msg} (错误代码: ${error.code})');
        },
      );
    } catch (e, stackTrace) {
      print('创建日程时发生异常: $e');
      print('异常堆栈: $stackTrace');
      
      // 重新抛出异常
      rethrow;
    }
  }

  // 更新日程
  Future<bool> updateSchedule(ScheduleItem schedule) async {
    try {
      // 更新数据库中的数据
      // 这里需要根据实际需求更新特定字段
      
      // 更新本地列表
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
        if (!_isDisposed) {
          notifyListeners();
        }

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
    try {
      print('开始删除日程: $scheduleId');
      
      // 使用当前视图ID，如果没有设置则使用默认的新建日程视图ID
      final viewId = _currentViewId ?? _newScheduleViewId;
      
      // 先查找要删除的日程（用于处理提醒）
      final scheduleToDelete = _schedules.where((s) => s.id == scheduleId).firstOrNull;
      
      // 从数据库删除
      await RowBackendService.deleteRows(viewId, [scheduleId]);

      // 如果找到了日程并且有提醒，则移除提醒
      if (scheduleToDelete?.reminderId != null) {
        _removeReminder(scheduleToDelete!.reminderId!);
      }

      // 从本地列表删除（使用removeWhere更安全）
      final removedCount = _schedules.length;
      _schedules.removeWhere((s) => s.id == scheduleId);
      final newCount = _schedules.length;
      
      print('删除日程完成: 删除前${removedCount}个，删除后${newCount}个');
      
      if (!_isDisposed) {
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('删除日程时发生错误: $e');
      // 即使本地操作失败，如果数据库删除成功，我们仍然应该刷新数据
      if (e.toString().contains('Bad state: No element')) {
        print('本地列表中未找到要删除的日程，可能已被其他操作删除，刷新数据...');
        refresh(); // 刷新数据以保持同步
        return true; // 数据库删除可能已经成功了
      }
      throw Exception('删除日程失败');
    }
  }

  // 设置提醒（使用 AppFlowy 提醒系统）
  void _setReminder(ScheduleItem schedule) async {
    try {
      final reminderBloc = getIt<ReminderBloc>();
      final reminderId = schedule.reminderId ?? nanoid();
      
      // 使用当前视图ID，如果没有设置则使用默认的新建日程视图ID
      final viewId = _currentViewId ?? _newScheduleViewId;
      
      reminderBloc.add(
        ReminderEvent.addById(
          reminderId: reminderId,
          objectId: viewId,
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

  // 切换日程完成状态（现在基于时间自动判断，此方法用于UI兼容性）
  Future<bool> toggleScheduleCompletion(String scheduleId) async {
    // 由于完成状态现在基于时间自动计算，这里只是触发UI更新
    // 实际的完成状态由 isCompleted getter 根据当前时间和结束时间计算
    try {
      if (!_isDisposed) {
        notifyListeners(); // 触发UI更新以反映最新的完成状态
      }
      return true;
    } catch (e) {
      print('更新日程状态时发生错误: $e');
    }
    return false;
  }

  // 更新数据库中的完成状态
  Future<void> _updateScheduleCompletionInDatabase(String scheduleId, bool isCompleted) async {
    try {
      // 使用当前视图ID，如果没有设置则使用默认的新建日程视图ID
      final viewId = _currentViewId ?? _newScheduleViewId;
      
      // TODO: 这里需要找到checkbox类型的字段ID，然后更新单元格数据
      // 目前作为占位符，在实际实现中需要：
      // 1. 获取视图的字段信息
      // 2. 找到类型为Checkbox的字段
      // 3. 使用CellBackendService更新该字段的值
      
      print('准备更新数据库中的完成状态: scheduleId=$scheduleId, isCompleted=$isCompleted, viewId=$viewId');
      
      // 暂时不实际更新数据库，避免出错
      // 在需要真正的数据库集成时，这里需要实现具体的更新逻辑
      
    } catch (e) {
      print('更新数据库完成状态时发生错误: $e');
    }
  }

  // 获取未完成的日程
  List<ScheduleItem> get incompleteSchedules => 
      _schedules.where((schedule) => !schedule.isCompleted).toList();

  // 获取已完成的日程
  List<ScheduleItem> get completedSchedules => 
      _schedules.where((schedule) => schedule.isCompleted).toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // 初始化数据库监听器
  Future<void> _initializeDatabaseListener(String viewId) async {
    try {
      // 清理之前的监听器
      _disposeDatabaseListener();
      
      // 获取ViewPB对象
      final viewResult = await ViewBackendService.getView(viewId);
      await viewResult.fold(
        (view) async {
          print('📋 获取到视图: ${view.name} (${view.id})');
          
          // 创建数据库控制器
          try {
            _databaseController = DatabaseController(view: view);
            print('✅ 数据库控制器创建成功');
          } catch (e) {
            print('❌ 创建数据库控制器失败: $e');
            throw Exception('创建数据库控制器失败: $e');
          }
          
          // 设置数据库回调
          _databaseCallbacks = DatabaseCallbacks(
            onRowsCreated: (rows) async {
              if (_isDisposed) return;
              print('🎉 检测到新行创建: ${rows.length} 行，ViewID: $viewId');
              // 新创建的行，重新加载数据
              await refresh();
            },
            onRowsUpdated: (rowIds, reason) async {
              if (_isDisposed) return;
              print('🔄 检测到行更新: ${rowIds.length} 行，ViewID: $viewId，原因: $reason');
              // 行更新，重新加载数据
              await refresh();
            },
            onRowsDeleted: (rowIds) async {
              if (_isDisposed) return;
              print('🗑️ 检测到行删除: ${rowIds.length} 行，ViewID: $viewId');
              // 行删除，重新加载数据
              await refresh();
            },
          );
          
          // 添加监听器
          if (_databaseController != null) {
            _databaseController!.addListener(onDatabaseChanged: _databaseCallbacks);
          }
          
          // 打开数据库连接
          print('🔓 正在打开数据库连接...');
          final openResult = await _databaseController!.open();
          await openResult.fold(
            (success) {
              print('✅ 数据库连接已打开，监听器初始化成功，viewId: $viewId');
              
              // 等待一下让字段控制器初始化
              Future.delayed(Duration(milliseconds: 100), () async {
                try {
                  // 打印字段信息 - 安全地访问字段控制器
                  final fieldController = _databaseController?.fieldController;
                  if (fieldController != null) {
                    final fieldInfos = fieldController.fieldInfos;
                    print('📋 可用字段信息:');
                    for (var field in fieldInfos) {
                      print('  - ${field.name} (${field.fieldType}) Primary: ${field.isPrimary}');
                    }
                  } else {
                    print('⚠️ 字段控制器尚未初始化，跳过字段信息打印');
                  }
                } catch (e) {
                  print('⚠️ 获取字段信息时出错: $e');
                }
              });
            },
            (error) {
              print('❌ 打开数据库连接失败: $error');
              throw Exception('无法打开数据库连接: $error');
            },
          );
        },
        (error) {
          print('获取视图失败: $error');
          throw Exception('无法获取视图: $error');
        },
      );
    } catch (e) {
      print('初始化数据库监听器失败: $e');
      // 清理失败的状态
      _databaseController = null;
      _databaseCallbacks = null;
      rethrow; // 重新抛出异常，让调用者知道初始化失败
    }
  }

  // 清理数据库监听器
  void _disposeDatabaseListener() {
    if (_databaseController != null && _databaseCallbacks != null) {
      _databaseController?.removeListener(onDatabaseChanged: _databaseCallbacks);
      // 异步清理，避免阻塞
      _databaseController?.dispose().ignore();
    }
    _databaseController = null;
    _databaseCallbacks = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeDatabaseListener();
    super.dispose();
  }
} 

// 使用AppFlowy内置的DatabaseEventGetAllCalendarEvents 