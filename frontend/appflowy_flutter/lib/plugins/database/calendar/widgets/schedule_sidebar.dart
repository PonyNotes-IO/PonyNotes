import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

class ScheduleSidebar extends StatefulWidget {
  const ScheduleSidebar({Key? key}) : super(key: key);

  @override
  State<ScheduleSidebar> createState() => _ScheduleSidebarState();
}

class _ScheduleSidebarState extends State<ScheduleSidebar> {
  late ScheduleManager _scheduleManager;
  
  // 控制收起展开的状态
  bool _isIncompleteExpanded = true;
  bool _isCompletedExpanded = true;
  
  @override
  void initState() {
    super.initState();
    _scheduleManager = ScheduleManager();
    // ScheduleManager会自动处理数据初始化，不需要手动调用
    _scheduleManager.addListener(_onScheduleChanged);
  }

  @override
  void dispose() {
    _scheduleManager.removeListener(_onScheduleChanged);
    super.dispose();
  }

  void _onScheduleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 我的日程标题
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '我的日程',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 日程内容
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScheduleSubSection('未完成', _scheduleManager.incompleteSchedules, _isIncompleteExpanded, () {
                  setState(() {
                    _isIncompleteExpanded = !_isIncompleteExpanded;
                  });
                }),
                SizedBox(height: 16),
                _buildScheduleSubSection('已完成', _scheduleManager.completedSchedules, _isCompletedExpanded, () {
                  setState(() {
                    _isCompletedExpanded = !_isCompletedExpanded;
                  });
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSubSection(String title, List<ScheduleItem> schedules, bool isExpanded, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.0 : 0.5,
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          if (schedules.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Center(
                child: Text(
                  '暂无内容',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            ...schedules.map((schedule) => _buildScheduleItem(schedule)),
        ],
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleItem schedule) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: schedule.color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.access_time,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      title: Text(
        schedule.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: schedule.isCompleted 
            ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)
            : null,
          decoration: schedule.isCompleted ? TextDecoration.lineThrough : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        schedule.timeText,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
      onTap: () => _showScheduleDetail(schedule),
    );
  }

  void _showScheduleDetail(ScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间: ${schedule.timeText}'),
            SizedBox(height: 8),
            Text('状态: ${schedule.statusText}'),
            SizedBox(height: 8),
            Text('分类: ${schedule.category}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}

// 新增：统一的日历内容组件
class CalendarContent extends StatefulWidget {
  final List<String> diaryItems;
  final DateTime? selectedDate;
  final String? viewId; // 添加视图ID参数

  const CalendarContent({
    Key? key, 
    required this.diaryItems,
    this.selectedDate,
    this.viewId, // 添加视图ID参数
  }) : super(key: key);

  @override
  State<CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  late ScheduleManager _scheduleManager;
  
  // 控制收起展开的状态
  bool _isIncompleteExpanded = true;
  bool _isCompletedExpanded = true;
  
  // 示例日记数据
  final List<Map<String, dynamic>> _diaryEntries = [
    {'title': '小马笔记教程', 'icon': '📚'},
    {'title': '星月考研笔记汇总', 'icon': '⭐'},
    {'title': '新东方考研日记', 'icon': '📖'},
    {'title': '无口祐笔记', 'icon': '✏️'},
  ];

  @override
  void initState() {
    super.initState();
    _scheduleManager = ScheduleManager();
    
    // 如果有视图ID，设置到ScheduleManager中
    if (widget.viewId != null && widget.viewId!.isNotEmpty) {
      _scheduleManager.setViewId(widget.viewId!);
    } else {
      // 如果没有视图ID，使用示例数据作为后备
      // 注意：这里不能直接调用私有方法，ScheduleManager会自动处理
    }
    
    _scheduleManager.addListener(_onScheduleChanged);
  }

  @override
  void didUpdateWidget(CalendarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果视图ID发生变化，重新设置
    if (oldWidget.viewId != widget.viewId && 
        widget.viewId != null && 
        widget.viewId!.isNotEmpty) {
      _scheduleManager.setViewId(widget.viewId!);
    }
  }

  @override
  void dispose() {
    _scheduleManager.removeListener(_onScheduleChanged);
    super.dispose();
  }

  void _onScheduleChanged() {
    if (mounted) setState(() {});
  }

  // 刷新数据
  Future<void> _refreshData() async {
    if (widget.viewId != null && widget.viewId!.isNotEmpty) {
      await _scheduleManager.refreshEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 格式化选中的日期
    String dateText;
    if (widget.selectedDate != null) {
      final date = widget.selectedDate!;
      dateText = '${date.year}年${date.month}月${date.day}日';
    } else {
      final today = DateTime.now();
      dateText = '${today.year}年${today.month}月${today.day}日';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 固定的日期标题（不滚动）
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 添加刷新按钮
              if (widget.viewId != null && widget.viewId!.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.refresh, size: 18),
                  onPressed: _refreshData,
                  tooltip: '刷新日程',
                ),
            ],
          ),
        ),
        // 滚动的内容区域，包含日记和日程
        Expanded(
          child: _scheduleManager.isLoading
              ? _buildLoadingIndicator()
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日记条目
                      ..._diaryEntries.map((entry) => _buildDiaryItem(entry)),
                      // 添加日记页按钮
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text(
                              '添加日记页',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // 日程条目
                      _buildScheduleSubSection('未完成', _scheduleManager.incompleteSchedules, _isIncompleteExpanded, () {
                        setState(() {
                          _isIncompleteExpanded = !_isIncompleteExpanded;
                        });
                      }),
                      SizedBox(height: 16),
                      _buildScheduleSubSection('已完成', _scheduleManager.completedSchedules, _isCompletedExpanded, () {
                        setState(() {
                          _isCompletedExpanded = !_isCompletedExpanded;
                        });
                      }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // 加载指示器
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '正在加载日程...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryItem(Map<String, dynamic> entry) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Text(entry['icon'], style: TextStyle(fontSize: 16)),
      title: Text(
        entry['title'],
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showDiaryDetail(entry),
    );
  }

  Widget _buildScheduleSubSection(String title, List<ScheduleItem> schedules, bool isExpanded, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.0 : 0.5,
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          if (schedules.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Center(
                child: Text(
                  '暂无内容',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            ...schedules.map((schedule) => _buildScheduleItem(schedule)),
        ],
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleItem schedule) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: schedule.color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.access_time,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      title: Text(
        schedule.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: schedule.isCompleted 
            ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)
            : null,
          decoration: schedule.isCompleted ? TextDecoration.lineThrough : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        schedule.timeText,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
      onTap: () => _showScheduleDetail(schedule),
    );
  }

  void _showDiaryDetail(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry['title']),
        content: Text('这是${entry['title']}的详细内容'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetail(ScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间: ${schedule.timeText}'),
            SizedBox(height: 8),
            Text('状态: ${schedule.statusText}'),
            SizedBox(height: 8),
            Text('分类: ${schedule.category}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
} 