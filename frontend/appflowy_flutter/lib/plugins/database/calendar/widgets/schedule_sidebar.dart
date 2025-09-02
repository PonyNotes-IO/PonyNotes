import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';

class ScheduleSidebar extends StatefulWidget {
  final String? databaseViewId; // 传入数据库视图ID以集成AppFlowy数据库
  final Function(ScheduleItem)? onScheduleTap; // 点击日程的回调

  const ScheduleSidebar({
    Key? key,
    this.databaseViewId,
    this.onScheduleTap,
  }) : super(key: key);

  @override
  State<ScheduleSidebar> createState() => _ScheduleSidebarState();
}

class _ScheduleSidebarState extends State<ScheduleSidebar> {
  late ScheduleModel _scheduleModel;
  Function(ScheduleItem)? _onScheduleTap;

  @override
  void initState() {
    super.initState();
    _scheduleModel = ScheduleModel();
    _onScheduleTap = widget.onScheduleTap;
    
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
      return const SizedBox.shrink(); // 显示空白而不是"暂无日程"提示
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 未完成日程区域
          if (incompleteSchedules.isNotEmpty) ...[
            _buildSectionHeader(context, '未完成', incompleteSchedules.length, model.isIncompleteExpanded, () {
              model.toggleIncompleteExpanded();
            }),
            if (model.isIncompleteExpanded) ...[
            const SizedBox(height: 8),
            ...incompleteSchedules.map((schedule) => 
              _buildScheduleCard(context, schedule, model)),
            ],
            const SizedBox(height: 16),
          ],
          
          // 已完成日程区域
          if (completedSchedules.isNotEmpty) ...[
            _buildSectionHeader(context, '已完成', completedSchedules.length, model.isCompletedExpanded, () {
              model.toggleCompletedExpanded();
            }),
            if (model.isCompletedExpanded) ...[
            const SizedBox(height: 8),
            ...completedSchedules.map((schedule) => 
              _buildScheduleCard(context, schedule, model)),
            ],
          ],
          
          // 底部留白，避免最后一个项目贴边
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, bool isExpanded, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
                title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, ScheduleItem schedule, ScheduleModel model) {
    // 计算持续时间显示
    final duration = schedule.endTime.difference(schedule.startTime);
    final durationText = _formatDuration(duration);
    
    // 格式化时间范围
    final timeRangeText = '${_formatDateTime(schedule.startTime)} - ${_formatDateTime(schedule.endTime)}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          // 设置选中状态
          model.selectSchedule(schedule.id);
          // 调用外部回调
          _onScheduleTap?.call(schedule);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 左侧彩色长条指示器
              Container(
                width: 4,
                height: 45,
                decoration: BoxDecoration(
                  color: model.isScheduleSelected(schedule.id) 
                    ? Colors.green 
                      : Colors.grey.shade400,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
              
              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 日程标题/描述
                      Text(
                        schedule.title.isNotEmpty ? schedule.title : schedule.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // 时间范围和持续时间
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              timeRangeText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (duration.inMinutes > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: schedule.isCompleted 
                                  ? Colors.green.withOpacity(0.1) 
                                  : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                durationText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: schedule.isCompleted ? Colors.green : Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 右侧箭头指示器
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h${minutes}m';
      } else {
        return '${hours}小时';
      }
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '< 1分钟';
    }
  }

  // 格式化日期时间，处理无效时间
  String _formatDateTime(DateTime dateTime) {
    // 检查是否是无效的时间戳（1970年或很早的时间）
    if (dateTime.year < 2000) {
      // 如果时间戳无效，使用当前时间
      dateTime = DateTime.now();
    }
    
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
      return '${dateTime.month}月${dateTime.day}日 ${_formatTimeOfDay(dateTime)}';
    }
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
  final Function(ScheduleItem)? onScheduleTap; // 点击日程的回调

  const ScheduleSidebarContent({
    Key? key,
    this.databaseViewId,
    this.onScheduleTap,
  }) : super(key: key);

  @override
  State<ScheduleSidebarContent> createState() => _ScheduleSidebarContentState();
}

class _ScheduleSidebarContentState extends State<ScheduleSidebarContent> {
  late ScheduleModel _scheduleModel;
  Function(ScheduleItem)? _onScheduleTap;

  @override
  void initState() {
    super.initState();
    _scheduleModel = ScheduleModel();
    _onScheduleTap = widget.onScheduleTap;
    
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
      return const SizedBox.shrink(); // 显示空白而不是"暂无日程"提示
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 未完成日程区域
        if (incompleteSchedules.isNotEmpty) ...[
          _buildSectionHeader(context, '未完成', incompleteSchedules.length, model.isIncompleteExpanded, () {
            model.toggleIncompleteExpanded();
          }),
          if (model.isIncompleteExpanded) ...[
          const SizedBox(height: 8),
          ...incompleteSchedules.map((schedule) => 
            _buildScheduleCard(context, schedule, model)),
          ],
          const SizedBox(height: 16),
        ],
        
        // 已完成日程区域
        if (completedSchedules.isNotEmpty) ...[
          _buildSectionHeader(context, '已完成', completedSchedules.length, model.isCompletedExpanded, () {
            model.toggleCompletedExpanded();
          }),
          if (model.isCompletedExpanded) ...[
          const SizedBox(height: 8),
          ...completedSchedules.map((schedule) => 
            _buildScheduleCard(context, schedule, model)),
          ],
        ],
        
        // 底部留白，避免最后一个项目贴边
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, bool isExpanded, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
                title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, ScheduleItem schedule, ScheduleModel model) {
    // 计算持续时间显示
    final duration = schedule.endTime.difference(schedule.startTime);
    final durationText = _formatDuration(duration);
    
    // 格式化时间范围
    final timeRangeText = '${_formatDateTime(schedule.startTime)} - ${_formatDateTime(schedule.endTime)}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          // 设置选中状态
          model.selectSchedule(schedule.id);
          // 调用外部回调
          _onScheduleTap?.call(schedule);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 左侧彩色长条指示器
              Container(
                width: 4,
                height: 45,
                decoration: BoxDecoration(
                  color: model.isScheduleSelected(schedule.id) 
                    ? Colors.green 
                      : Colors.grey.shade400,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),
              
              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 日程标题/描述
                      Text(
                        schedule.title.isNotEmpty ? schedule.title : schedule.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // 时间范围和持续时间
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              timeRangeText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (duration.inMinutes > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: schedule.isCompleted 
                                  ? Colors.green.withOpacity(0.1) 
                                  : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                durationText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: schedule.isCompleted ? Colors.green : Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 右侧箭头指示器
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h${minutes}m';
      } else {
        return '${hours}小时';
      }
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '< 1分钟';
    }
  }

  // 格式化日期时间，处理无效时间
  String _formatDateTime(DateTime dateTime) {
    // 检查是否是无效的时间戳（1970年或很早的时间）
    if (dateTime.year < 2000) {
      // 如果时间戳无效，使用当前时间
      dateTime = DateTime.now();
    }
    
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
      return '${dateTime.month}月${dateTime.day}日 ${_formatTimeOfDay(dateTime)}';
    }
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