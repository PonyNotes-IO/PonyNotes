import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/homepage/application/todo_bloc.dart';
import 'package:appflowy/plugins/homepage/application/todo_models.dart';
import 'package:appflowy/plugins/homepage/widgets/quick_event_creator.dart';
import 'package:appflowy/plugins/homepage/widgets/todo_list_display.dart';

/// 主页待办计划区域的主组件
/// 包含左侧的快速创建区域和右侧的待办列表展示
class TodoPlanSection extends StatelessWidget {
  const TodoPlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc()..add(const TodoEvent.initial()),
      child: const TodoPlanSectionContent(),
    );
  }
}

class TodoPlanSectionContent extends StatelessWidget {
  const TodoPlanSectionContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 266,
        maxHeight: 400,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：快速创建待办区域
                Expanded(
                  flex: 1,
                  child: QuickEventCreator(
                    onEventCreated: (event) {
                      // 创建成功后刷新待办列表
                      context.read<TodoBloc>().add(const TodoEvent.loadTodos());
                    },
                  ),
                ),
                // 分割线
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  color: const Color(0xFFE9E9E9),
                ),
                // 右侧：待办列表展示区域
                Expanded(
                  flex: 2,
                  child: TodoListDisplay(
                    todayTodos: state.todayTodos,
                    upcomingTodos: state.upcomingTodos,
                    onTodoToggle: (todoId) {
                      context.read<TodoBloc>().add(TodoEvent.toggleComplete(todoId));
                    },
                    onTodoAdd: () {
                      // 可以触发左侧的创建区域或打开完整的创建对话框
                      _showAddTodoDialog(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    // TODO: 实现添加待办的对话框
    // 这里可以复用日历的NewEventPage或创建简化版本
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加待办'),
        content: const Text('此功能将在后续开发中实现'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
