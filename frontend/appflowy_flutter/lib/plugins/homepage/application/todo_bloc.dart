import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/homepage/application/todo_models.dart';
import 'package:appflowy/plugins/homepage/application/todo_service.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  late final StreamSubscription _todosSubscription;
  final TodoService _todoService = TodoService.instance;

  TodoBloc() : super(const TodoState()) {
    _dispatch();
    _initializeService();
  }

  void _dispatch() {
    on<TodoEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            emit(state.copyWith(isLoading: true));
            await _todoService.initialize();
            await _loadAllTodos(emit);
          },
          addTodo: (todo) async {
            await _todoService.addTodo(todo);
            await _loadAllTodos(emit);
          },
          updateTodo: (todo) async {
            await _todoService.updateTodo(todo);
            await _loadAllTodos(emit);
          },
          deleteTodo: (id) async {
            await _todoService.deleteTodo(id);
            await _loadAllTodos(emit);
          },
          toggleComplete: (id) async {
            await _todoService.toggleComplete(id);
            await _loadAllTodos(emit);
          },
          loadTodos: () async {
            emit(state.copyWith(isLoading: true));
            await _loadAllTodos(emit);
          },
          filterTodos: (filter) async {
            emit(state.copyWith(currentFilter: filter));
            await _loadAllTodos(emit);
          },
          sortTodos: (sort) async {
            emit(state.copyWith(currentSort: sort));
            await _loadAllTodos(emit);
          },
          loadTodayTodos: () async {
            final todayTodos = await _todoService.getTodayTodos();
            emit(state.copyWith(todayTodos: todayTodos));
          },
          loadUpcomingTodos: () async {
            final upcomingTodos = await _todoService.getUpcomingTodos();
            emit(state.copyWith(upcomingTodos: upcomingTodos));
          },
        );
      },
    );
  }

  void _initializeService() {
    _todosSubscription = _todoService.todosStream.listen((todos) {
      if (!isClosed) {
        add(const TodoEvent.loadTodos());
      }
    });
  }

  Future<void> _loadAllTodos(Emitter<TodoState> emit) async {
    try {
      List<TodoItem> allTodos = await _todoService.getAllTodos();
      
      // 根据当前筛选器过滤待办事项
      List<TodoItem> filteredTodos;
      switch (state.currentFilter) {
        case TodoFilter.all:
          filteredTodos = allTodos;
          break;
        case TodoFilter.today:
          filteredTodos = await _todoService.getTodayTodos();
          break;
        case TodoFilter.upcoming:
          filteredTodos = await _todoService.getUpcomingTodos();
          break;
        case TodoFilter.completed:
          filteredTodos = await _todoService.getCompletedTodos();
          break;
        case TodoFilter.incomplete:
          filteredTodos = await _todoService.getIncompleteTodos();
          break;
      }

      // 排序
      filteredTodos = _todoService.sortTodos(filteredTodos, state.currentSort);

      // 获取今天和即将到来的待办事项
      final todayTodos = await _todoService.getTodayTodos();
      final upcomingTodos = await _todoService.getUpcomingTodos();
      final completedTodos = await _todoService.getCompletedTodos();

      emit(state.copyWith(
        todos: filteredTodos,
        todayTodos: todayTodos,
        upcomingTodos: upcomingTodos,
        completedTodos: completedTodos,
        isLoading: false,
        errorMessage: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加载待办事项失败: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _todosSubscription.cancel();
    return super.close();
  }
}

