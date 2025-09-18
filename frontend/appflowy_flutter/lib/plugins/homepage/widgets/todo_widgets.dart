import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:appflowy/plugins/homepage/application/todo_models.dart';
import 'package:appflowy/plugins/homepage/application/todo_bloc.dart';

class TodoSection extends StatelessWidget {
  const TodoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc()..add(const TodoEvent.initial()),
      child: const TodoSectionContent(),
    );
  }
}

class TodoSectionContent extends StatelessWidget {
  const TodoSectionContent({super.key});

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
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                state.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：今天的任务
                Expanded(
                  flex: 2,
                  child: _buildTodaySection(context, state),
                ),
                // 分割线
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  color: const Color(0xFFE9E9E9),
                ),
                // 右侧：即将到来的任务
                Expanded(
                  flex: 2,
                  child: _buildUpcomingSection(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, TodoState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.today,
              size: 18,
              color: Color(0xFF636363),
            ),
            const SizedBox(width: 8),
            const Text(
              '今天',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF636363),
              ),
            ),
            const Spacer(),
            _buildAddTodoButton(context),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildTodoList(context, state.todayTodos),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(BuildContext context, TodoState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.schedule,
              size: 18,
              color: Color(0xFF636363),
            ),
            SizedBox(width: 8),
            Text(
              '即将到来',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF636363),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildTodoList(context, state.upcomingTodos),
        ),
      ],
    );
  }

  Widget _buildAddTodoButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddTodoDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8D69).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: Color(0xFFFF8D69),
            ),
            SizedBox(width: 4),
            Text(
              '添加',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF8D69),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList(BuildContext context, List<TodoItem> todos) {
    if (todos.isEmpty) {
      return const Center(
        child: Text(
          '暂无待办事项',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoItemWidget(todo: todo);
      },
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TodoBloc>(),
        child: const AddTodoDialog(),
      ),
    );
  }
}

class TodoItemWidget extends StatelessWidget {
  final TodoItem todo;

  const TodoItemWidget({
    super.key,
    required this.todo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: todo.isCompleted 
            ? const Color(0xFFF5F5F5) 
            : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 完成状态复选框
          GestureDetector(
            onTap: () => context.read<TodoBloc>().add(
              TodoEvent.toggleComplete(todo.id),
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: todo.isCompleted 
                    ? const Color(0xFFFF8D69) 
                    : Colors.white,
                border: Border.all(
                  color: todo.isCompleted 
                      ? const Color(0xFFFF8D69) 
                      : const Color(0xFFD0D0D0),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: todo.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // 待办内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: todo.isCompleted 
                        ? const Color(0xFF888888) 
                        : const Color(0xFF333333),
                    decoration: todo.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    todo.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: todo.isCompleted 
                          ? const Color(0xFF888888) 
                          : const Color(0xFF666666),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (todo.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: _getDueDateColor(todo.dueDate!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDueDate(todo.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDueDateColor(todo.dueDate!),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
              // 来源和优先级指示器
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 来源标识
                  if (todo.source == TodoSource.calendar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: const Color(0xFF4285F4),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '日历',
                            style: TextStyle(
                              fontSize: 9,
                              color: const Color(0xFF4285F4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 间距
                  if (todo.source == TodoSource.calendar && todo.priority != TodoPriority.medium)
                    const SizedBox(width: 6),
                  
                  // 优先级指示器
                  if (todo.priority != TodoPriority.medium)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(todo.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.none:
        return const Color(0xFF9E9E9E);
      case TodoPriority.low:
        return const Color(0xFF4CAF50);
      case TodoPriority.medium:
        return const Color(0xFFFF9800);
      case TodoPriority.high:
        return const Color(0xFFFF5722);
      case TodoPriority.urgent:
        return const Color(0xFFF44336);
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (dueDateDay.isBefore(today)) {
      return const Color(0xFFF44336); // 过期 - 红色
    } else if (dueDateDay.isAtSameMomentAs(today)) {
      return const Color(0xFFFF8D69); // 今天 - 橙色
    } else {
      return const Color(0xFF666666); // 未来 - 灰色
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (dueDateDay.isAtSameMomentAs(today)) {
      return '今天 ${DateFormat('HH:mm').format(dueDate)}';
    } else if (dueDateDay.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return '明天 ${DateFormat('HH:mm').format(dueDate)}';
    } else if (dueDateDay.year == today.year) {
      return DateFormat('MM/dd HH:mm').format(dueDate);
    } else {
      return DateFormat('yyyy/MM/dd').format(dueDate);
    }
  }
}

class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  TodoPriority _selectedPriority = TodoPriority.medium;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加待办事项'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TodoPriority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: '优先级',
                      border: OutlineInputBorder(),
                    ),
                    items: TodoPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      );
                    }).toList(),
                    onChanged: (priority) {
                      if (priority != null) {
                        setState(() => _selectedPriority = priority);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '截止日期',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDueDate != null
                            ? DateFormat('yyyy/MM/dd HH:mm').format(_selectedDueDate!)
                            : '选择日期',
                        style: TextStyle(
                          color: _selectedDueDate != null 
                              ? Colors.black 
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _addTodo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8D69),
          ),
          child: const Text('添加', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addTodo() {
    if (_titleController.text.trim().isEmpty) return;

    final todo = TodoItem(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
    );

    context.read<TodoBloc>().add(TodoEvent.addTodo(todo));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
