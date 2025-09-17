import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_models.freezed.dart';
part 'todo_models.g.dart';

@freezed
class TodoItem with _$TodoItem {
  const factory TodoItem({
    required String id,
    required String title,
    @Default('') String description,
    @Default(false) bool isCompleted,
    @Default(TodoPriority.medium) TodoPriority priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    @Default([]) List<String> tags,
    @Default(TodoSource.manual) TodoSource source,
    @Default(false) bool isAllDay,
  }) = _TodoItem;

  factory TodoItem.fromJson(Map<String, dynamic> json) => _$TodoItemFromJson(json);
}

@freezed
class TodoState with _$TodoState {
  const factory TodoState({
    @Default([]) List<TodoItem> todos,
    @Default([]) List<TodoItem> todayTodos,
    @Default([]) List<TodoItem> upcomingTodos,
    @Default([]) List<TodoItem> completedTodos,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default(TodoFilter.all) TodoFilter currentFilter,
    @Default(TodoSort.dueDate) TodoSort currentSort,
  }) = _TodoState;
}

@freezed
class TodoEvent with _$TodoEvent {
  const factory TodoEvent.initial() = _Initial;
  const factory TodoEvent.addTodo(TodoItem todo) = _AddTodo;
  const factory TodoEvent.updateTodo(TodoItem todo) = _UpdateTodo;
  const factory TodoEvent.deleteTodo(String id) = _DeleteTodo;
  const factory TodoEvent.toggleComplete(String id) = _ToggleComplete;
  const factory TodoEvent.loadTodos() = _LoadTodos;
  const factory TodoEvent.filterTodos(TodoFilter filter) = _FilterTodos;
  const factory TodoEvent.sortTodos(TodoSort sort) = _SortTodos;
  const factory TodoEvent.loadTodayTodos() = _LoadTodayTodos;
  const factory TodoEvent.loadUpcomingTodos() = _LoadUpcomingTodos;
}

enum TodoPriority {
  none,
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TodoPriority.none:
        return '无';
      case TodoPriority.low:
        return '低';
      case TodoPriority.medium:
        return '中';
      case TodoPriority.high:
        return '高';
      case TodoPriority.urgent:
        return '紧急';
    }
  }

  int get value {
    switch (this) {
      case TodoPriority.none:
        return 0;
      case TodoPriority.low:
        return 1;
      case TodoPriority.medium:
        return 2;
      case TodoPriority.high:
        return 3;
      case TodoPriority.urgent:
        return 4;
    }
  }
}

enum TodoFilter {
  all,
  today,
  upcoming,
  completed,
  incomplete;

  String get displayName {
    switch (this) {
      case TodoFilter.all:
        return '全部';
      case TodoFilter.today:
        return '今天';
      case TodoFilter.upcoming:
        return '即将到来';
      case TodoFilter.completed:
        return '已完成';
      case TodoFilter.incomplete:
        return '未完成';
    }
  }
}

enum TodoSort {
  dueDate,
  priority,
  createdAt,
  alphabetical;

  String get displayName {
    switch (this) {
      case TodoSort.dueDate:
        return '截止日期';
      case TodoSort.priority:
        return '优先级';
      case TodoSort.createdAt:
        return '创建时间';
      case TodoSort.alphabetical:
        return '字母顺序';
    }
  }
}

enum TodoSource {
  manual,
  calendar;

  String get displayName {
    switch (this) {
      case TodoSource.manual:
        return '手动创建';
      case TodoSource.calendar:
        return '日历导入';
    }
  }
}
