import 'dart:async';
import 'dart:convert';
import 'package:appflowy/plugins/homepage/application/todo_models.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoService {
  static const String _todosKey = 'homepage_todos';
  static TodoService? _instance;
  
  static TodoService get instance => _instance ??= TodoService._();
  
  TodoService._();

  final StreamController<List<TodoItem>> _todosController = StreamController<List<TodoItem>>.broadcast();
  List<TodoItem> _todos = [];
  String? _calendarViewId; // 日历视图ID

  Stream<List<TodoItem>> get todosStream => _todosController.stream;
  List<TodoItem> get todos => List.unmodifiable(_todos);

  Future<void> initialize() async {
    // 初始化日历视图ID
    _calendarViewId = fixedUuid(12345, UuidType.privateSpace);
    await _loadTodos();
  }

  Future<List<TodoItem>> getAllTodos() async {
    if (_todos.isEmpty) {
      await _loadTodos();
    }
    
    // 合并本地待办和日历日程
    final allTodos = List<TodoItem>.from(_todos);
    final calendarTodos = await _loadCalendarTodos();
    allTodos.addAll(calendarTodos);
    
    return List.unmodifiable(allTodos);
  }

  Future<List<TodoItem>> getTodayTodos() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 合并本地待办和日历日程
    final allTodos = await getAllTodos();
    
    return allTodos.where((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.isAfter(today.subtract(const Duration(milliseconds: 1))) &&
             todo.dueDate!.isBefore(tomorrow) &&
             !todo.isCompleted;
    }).toList();
  }

  Future<List<TodoItem>> getUpcomingTodos() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    // 合并本地待办和日历日程
    final allTodos = await getAllTodos();
    
    return allTodos.where((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.isAfter(today) &&
             todo.dueDate!.isBefore(nextWeek.add(const Duration(days: 1))) &&
             !todo.isCompleted;
    }).toList();
  }

  Future<List<TodoItem>> getCompletedTodos() async {
    return _todos.where((todo) => todo.isCompleted).toList();
  }

  Future<List<TodoItem>> getIncompleteTodos() async {
    return _todos.where((todo) => !todo.isCompleted).toList();
  }

  Future<void> addTodo(TodoItem todo) async {
    final newTodo = todo.copyWith(
      id: todo.id.isEmpty ? _generateId() : todo.id,
      createdAt: todo.createdAt ?? DateTime.now(),
    );
    
    _todos.add(newTodo);
    await _saveTodos();
    _todosController.add(List.unmodifiable(_todos));
  }

  Future<void> updateTodo(TodoItem updatedTodo) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      await _saveTodos();
      _todosController.add(List.unmodifiable(_todos));
    }
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    await _saveTodos();
    _todosController.add(List.unmodifiable(_todos));
  }

  Future<void> toggleComplete(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: !todo.isCompleted ? DateTime.now() : null,
      );
      _todos[index] = updatedTodo;
      await _saveTodos();
      _todosController.add(List.unmodifiable(_todos));
    }
  }

  List<TodoItem> sortTodos(List<TodoItem> todos, TodoSort sort) {
    final sortedTodos = List<TodoItem>.from(todos);
    
    switch (sort) {
      case TodoSort.dueDate:
        sortedTodos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TodoSort.priority:
        sortedTodos.sort((a, b) => b.priority.value.compareTo(a.priority.value));
        break;
      case TodoSort.createdAt:
        sortedTodos.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case TodoSort.alphabetical:
        sortedTodos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    
    return sortedTodos;
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getString(_todosKey);
      
      if (todosJson != null) {
        final List<dynamic> todosList = json.decode(todosJson);
        _todos = todosList.map((json) {
          try {
            return TodoItem.fromJson(json);
          } catch (e) {
            // 处理旧版本数据，添加默认的source字段
            final Map<String, dynamic> updatedJson = Map<String, dynamic>.from(json);
            if (!updatedJson.containsKey('source')) {
              updatedJson['source'] = 'manual'; // 默认为手动创建
            }
            return TodoItem.fromJson(updatedJson);
          }
        }).toList();
      } else {
        // 添加一些示例数据
        _todos = _createSampleTodos();
        await _saveTodos();
      }
      
      _todosController.add(List.unmodifiable(_todos));
    } catch (e) {
      print('加载待办事项时出错: $e');
      // 清除可能损坏的数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_todosKey);
      
      _todos = _createSampleTodos();
      await _saveTodos();
      _todosController.add(List.unmodifiable(_todos));
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = json.encode(_todos.map((todo) => todo.toJson()).toList());
      await prefs.setString(_todosKey, todosJson);
    } catch (e) {
      // 处理保存错误
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  List<TodoItem> _createSampleTodos() {
    final now = DateTime.now();
    return [
      TodoItem(
        id: '1',
        title: '完成项目报告',
        description: '准备下周一的项目进度报告',
        priority: TodoPriority.high,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        tags: ['工作', '报告'],
      ),
      TodoItem(
        id: '2',
        title: '购买生活用品',
        description: '牛奶、面包、水果',
        priority: TodoPriority.medium,
        dueDate: now.add(const Duration(hours: 6)),
        createdAt: now.subtract(const Duration(days: 1)),
        tags: ['生活', '购物'],
      ),
      TodoItem(
        id: '3',
        title: '锻炼身体',
        description: '跑步30分钟',
        priority: TodoPriority.medium,
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(hours: 12)),
        tags: ['健康', '运动'],
      ),
      TodoItem(
        id: '4',
        title: '学习新技能',
        description: '完成Flutter教程第3章',
        priority: TodoPriority.low,
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(hours: 6)),
        tags: ['学习', '技术'],
        isCompleted: true,
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  // 从日历加载待办事项
  Future<List<TodoItem>> _loadCalendarTodos() async {
    if (_calendarViewId == null) return [];
    
    try {
      final payload = CalendarEventRequestPB.create()..viewId = _calendarViewId!;
      final result = await DatabaseEventGetAllCalendarEvents(payload).send();
      
      return result.fold(
        (events) {
          final calendarTodos = <TodoItem>[];
          
          for (final eventPB in events.items) {
            // 将日历事件转换为待办事项
            final todo = _convertCalendarEventToTodo(eventPB);
            if (todo != null) {
              calendarTodos.add(todo);
            }
          }
          
          return calendarTodos;
        },
        (error) {
          return <TodoItem>[];
        },
      );
    } catch (e) {
      return <TodoItem>[];
    }
  }

  // 将日历事件转换为待办事项
  TodoItem? _convertCalendarEventToTodo(CalendarEventPB eventPB) {
    try {
      final timestamp = eventPB.timestamp;
      final endTimestamp = eventPB.endTimestamp;
      
      final dueDate = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
      final endDate = DateTime.fromMillisecondsSinceEpoch(endTimestamp.toInt() * 1000);
      
      // 如果事件已经结束，标记为完成
      final now = DateTime.now();
      final isCompleted = now.isAfter(endDate);
      
      return TodoItem(
        id: 'calendar_${eventPB.rowMeta.id}', // 加前缀区分日历事件
        title: eventPB.title.isNotEmpty ? eventPB.title : '日历事件',
        description: '来自日历的日程安排',
        priority: TodoPriority.medium,
        dueDate: dueDate,
        createdAt: dueDate,
        isCompleted: isCompleted,
        completedAt: isCompleted ? endDate : null,
        tags: ['日历', '日程'],
        source: TodoSource.calendar, // 标记来源为日历
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _todosController.close();
  }
}
