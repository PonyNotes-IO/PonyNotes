import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';

class ScheduleSidebar extends StatefulWidget {
  final String? databaseViewId; // 传入数据库视图ID以集成AppFlowy数据库

  const ScheduleSidebar({
    Key? key,
    this.databaseViewId,
  }) : super(key: key);

  @override
  State<ScheduleSidebar> createState() => _ScheduleSidebarState();
}

class _ScheduleSidebarState extends State<ScheduleSidebar> {
  late ScheduleModel _scheduleModel;

  @override
  void initState() {
    super.initState();
    _scheduleModel = ScheduleModel();
    
    // 如果提供了数据库视图ID，设置为数据库集成模式
    if (widget.databaseViewId != null && widget.databaseViewId!.isNotEmpty) {
      _scheduleModel.setViewId(widget.databaseViewId!);
    }
  }

  @override
  void dispose() {
    _scheduleModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _scheduleModel,
      child: SizedBox(
        width: 300,
        child: Consumer<ScheduleModel>(
          builder: (context, model, child) {
            if (model.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return _buildScheduleList(context, model);
          },
        ),
      ),
    );
  }



  Widget _buildScheduleList(BuildContext context, ScheduleModel model) {
    final incompleteSchedules = model.incompleteSchedules;
    final completedSchedules = model.completedSchedules;

    if (model.schedules.isEmpty) {
      return const SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '暂无日程',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '点击"+"创建新日程',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 未完成日程区域
          if (incompleteSchedules.isNotEmpty) ...[
            _buildSectionHeader(context, '未完成', incompleteSchedules.length),
            const SizedBox(height: 8),
            ...incompleteSchedules.map((schedule) => 
              _buildScheduleCard(context, schedule, model)),
            const SizedBox(height: 16),
          ],
          
          // 已完成日程区域
          if (completedSchedules.isNotEmpty) ...[
            _buildSectionHeader(context, '已完成', completedSchedules.length),
            const SizedBox(height: 8),
            ...completedSchedules.map((schedule) => 
              _buildScheduleCard(context, schedule, model)),
          ],
          
          // 底部留白，避免最后一个项目贴边
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$title ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, ScheduleItem schedule, ScheduleModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 完成状态指示器（基于时间自动判断）
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: schedule.isCompleted,
              onChanged: null, // 禁用手动切换，因为状态基于时间自动计算
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: schedule.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
              checkColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          // 内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: schedule.isCompleted ? TextDecoration.lineThrough : null,
                    color: schedule.isCompleted 
                        ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey.withOpacity(0.6)
                        : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (schedule.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    schedule.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      decoration: schedule.isCompleted ? TextDecoration.lineThrough : null,
                      color: schedule.isCompleted 
                          ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5)
                          : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (scheduleDate == today) {
      return '今天 ${_formatTimeOfDay(dateTime)}';
    } else if (scheduleDate == today.add(const Duration(days: 1))) {
      return '明天 ${_formatTimeOfDay(dateTime)}';
    } else if (scheduleDate == today.subtract(const Duration(days: 1))) {
      return '昨天 ${_formatTimeOfDay(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${_formatTimeOfDay(dateTime)}';
    }
  }

  String _formatTimeOfDay(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateScheduleDialog(BuildContext context) {
    final model = context.read<ScheduleModel>();
    
    if (model.currentViewId != null) {
      // 在数据库集成模式下，直接创建空行，用户可以在行详情页编辑
      model.createSchedule(
        title: '新日程',
        description: '',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已创建新日程，请在日历视图中编辑详细信息'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 在本地模式下，显示创建对话框
      _showLocalCreateDialog(context, model);
    }
  }

  void _showLocalCreateDialog(BuildContext context, ScheduleModel model) {
    // 这里可以实现一个简单的创建对话框
    // 由于主要使用 AppFlowy 集成模式，这里简化处理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请连接到 AppFlowy 数据库以创建日程'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showScheduleDetails(BuildContext context, ScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          schedule.title,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedule.description.isNotEmpty) ...[
              Text(
                '描述：${schedule.description}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '开始时间：${_formatFullTime(schedule.startTime)}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              '结束时间：${_formatFullTime(schedule.endTime)}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (schedule.reminderOption != ReminderOption.none) ...[
              const SizedBox(height: 8),
              Text(
                '提醒：${schedule.reminderOption.label}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${_formatTimeOfDay(dateTime)}';
  }
}

// 不带滚动条的日程内容组件，用于嵌入到外部的统一滚动视图中
class ScheduleSidebarContent extends StatefulWidget {
  final String? databaseViewId;

  const ScheduleSidebarContent({
    Key? key,
    this.databaseViewId,
  }) : super(key: key);

  @override
  State<ScheduleSidebarContent> createState() => _ScheduleSidebarContentState();
}

class _ScheduleSidebarContentState extends State<ScheduleSidebarContent> {
  late ScheduleModel _scheduleModel;

  @override
  void initState() {
    super.initState();
    _scheduleModel = ScheduleModel();
    
    if (widget.databaseViewId != null && widget.databaseViewId!.isNotEmpty) {
      _scheduleModel.setViewId(widget.databaseViewId!);
    }
  }

  @override
  void dispose() {
    _scheduleModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _scheduleModel,
      child: Consumer<ScheduleModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return _buildScheduleContent(context, model);
        },
      ),
    );
  }

  Widget _buildScheduleContent(BuildContext context, ScheduleModel model) {
    final incompleteSchedules = model.incompleteSchedules;
    final completedSchedules = model.completedSchedules;

    if (model.schedules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无日程',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 未完成日程区域
        if (incompleteSchedules.isNotEmpty) ...[
          _buildSectionHeader(context, '未完成', incompleteSchedules.length),
          const SizedBox(height: 8),
          ...incompleteSchedules.map((schedule) => 
            _buildScheduleCard(context, schedule, model)),
          const SizedBox(height: 16),
        ],
        
        // 已完成日程区域
        if (completedSchedules.isNotEmpty) ...[
          _buildSectionHeader(context, '已完成', completedSchedules.length),
          const SizedBox(height: 8),
          ...completedSchedules.map((schedule) => 
            _buildScheduleCard(context, schedule, model)),
        ],
        
        // 底部留白，避免最后一个项目贴边
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$title ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, ScheduleItem schedule, ScheduleModel model) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 完成状态复选框
          GestureDetector(
            onTap: () {
              model.toggleScheduleCompletion(schedule.id);
            },
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: schedule.isCompleted 
                    ? Colors.green 
                    : Theme.of(context).dividerColor,
                  width: 2,
                ),
                color: schedule.isCompleted 
                  ? Colors.green 
                  : Colors.transparent,
              ),
              child: schedule.isCompleted
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
            ),
          ),
          
          // 日程内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: schedule.isCompleted 
                      ? TextDecoration.lineThrough 
                      : null,
                    color: schedule.isCompleted 
                      ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                      : null,
                  ),
                ),
                if (schedule.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    schedule.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      decoration: schedule.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                    ),
                  ),
                ],
                if (schedule.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatFullTime(schedule.dueDate!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getDueDateColor(schedule.dueDate!),
                      decoration: schedule.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red; // 已过期
    } else if (difference == 0) {
      return Colors.orange; // 今天到期
    } else if (difference <= 3) {
      return Colors.amber; // 3天内到期
    } else {
      return Colors.grey; // 正常
    }
  }

  String _formatTimeOfDay(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFullTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${_formatTimeOfDay(dateTime)}';
  }
} 