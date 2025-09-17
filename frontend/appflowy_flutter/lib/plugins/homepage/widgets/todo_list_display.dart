import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appflowy/plugins/homepage/application/todo_models.dart';

/// 待办列表展示组件
/// 显示今天和即将到来的待办事项，支持交互操作
class TodoListDisplay extends StatelessWidget {
  final List<TodoItem> todayTodos;
  final List<TodoItem> upcomingTodos;
  final Function(String todoId)? onTodoToggle;

  const TodoListDisplay({
    super.key,
    required this.todayTodos,
    required this.upcomingTodos,
    this.onTodoToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            const Icon(
              Icons.checklist,
              size: 18,
              color: Color(0xFF636363),
            ),
            const SizedBox(width: 8),
            const Text(
              "待办",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 内容区域
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 今天的待办
                _buildTodaySection(),
                
                // 间距
                if (todayTodos.isNotEmpty && upcomingTodos.isNotEmpty)
                  const SizedBox(height: 20),
                
                // 即将到来的待办
                if (upcomingTodos.isNotEmpty)
                  _buildUpcomingSection(),
                
                // 空状态
                if (todayTodos.isEmpty && upcomingTodos.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    if (todayTodos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "今天",
          DateFormat('M月d日').format(DateTime.now()),
          todayTodos.length,
        ),
        const SizedBox(height: 8),
        ...todayTodos.map((todo) => _buildTodoItem(todo)),
      ],
    );
  }

  Widget _buildUpcomingSection() {
    if (upcomingTodos.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按日期分组
    final groupedTodos = <String, List<TodoItem>>{};
    for (final todo in upcomingTodos) {
      if (todo.dueDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(todo.dueDate!);
        if (!groupedTodos.containsKey(dateKey)) {
          groupedTodos[dateKey] = [];
        }
        groupedTodos[dateKey]!.add(todo);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "即将到来",
          "",
          upcomingTodos.length,
        ),
        const SizedBox(height: 8),
        ...groupedTodos.entries.map((entry) {
          final date = DateTime.parse(entry.key);
          final todos = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期标题
              Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 8),
                child: Text(
                  _formatUpcomingDate(date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              // 该日期的待办事项
              ...todos.map((todo) => _buildTodoItem(todo)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, int count) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: todo.isCompleted 
            ? Colors.grey[50] 
            : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: todo.isCompleted 
              ? Colors.grey[300]! 
              : const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 完成状态复选框
          InkWell(
            onTap: () => onTodoToggle?.call(todo.id),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: todo.isCompleted 
                    ? const Color(0xFF10B981) 
                    : Colors.white,
                border: Border.all(
                  color: todo.isCompleted 
                      ? const Color(0xFF10B981) 
                      : Colors.grey[400]!,
                  width: 1,
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
          const SizedBox(width: 10),
          
          // 待办内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: todo.isCompleted 
                        ? Colors.grey[600] 
                        : const Color(0xFF333333),
                    decoration: todo.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // 时间和优先级
                if (todo.dueDate != null || todo.priority != TodoPriority.none)
                  const SizedBox(height: 4),
                if (todo.dueDate != null || todo.priority != TodoPriority.none)
                  Row(
                    children: [
                      // 时间
                      if (todo.dueDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 10,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatTodoTime(todo),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      
                      // 优先级
                      if (todo.priority != TodoPriority.none)
                        Row(
                          children: [
                            if (todo.dueDate != null) 
                              const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(todo.priority).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                _getPriorityText(todo.priority),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _getPriorityColor(todo.priority),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            "暂无待办事项",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "点击左侧创建你的第一个待办",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpcomingDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dayAfterTomorrow = DateTime(now.year, now.month, now.day + 2);
    
    if (date.year == tomorrow.year && 
        date.month == tomorrow.month && 
        date.day == tomorrow.day) {
      return "明天 ${DateFormat('M月d日').format(date)}";
    } else if (date.year == dayAfterTomorrow.year && 
               date.month == dayAfterTomorrow.month && 
               date.day == dayAfterTomorrow.day) {
      return "后天 ${DateFormat('M月d日').format(date)}";
    } else {
      return DateFormat('M月d日 EEEE', 'zh_CN').format(date);
    }
  }

  String _formatTodoTime(TodoItem todo) {
    if (todo.dueDate == null) return "";
    
    // 如果是全天事件或没有具体时间，只显示日期
    if (todo.isAllDay) {
      return "全天";
    }
    
    // 显示具体时间
    return DateFormat('HH:mm').format(todo.dueDate!);
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.urgent:
        return Colors.red[700]!;
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.blue;
      case TodoPriority.none:
        return Colors.grey;
    }
  }

  String _getPriorityText(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.urgent:
        return "紧急";
      case TodoPriority.high:
        return "高";
      case TodoPriority.medium:
        return "中";
      case TodoPriority.low:
        return "低";
      case TodoPriority.none:
        return "";
    }
  }
}
