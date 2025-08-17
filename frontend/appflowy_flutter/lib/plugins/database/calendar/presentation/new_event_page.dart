import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewEventPage extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onEventCreated;
  final VoidCallback onCancel;
  final Function(bool Function())? onSaveRequested;

  const NewEventPage({
    Key? key,
    required this.selectedDate,
    required this.onEventCreated,
    required this.onCancel,
    this.onSaveRequested,
  }) : super(key: key);

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  bool _isImportant = false;
  bool _isRepeat = false;
  String _calendar = '我的日历';
  String _description = '';

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    
    // 设置保存回调
    if (widget.onSaveRequested != null) {
      widget.onSaveRequested!(saveEvent);
    }
  }

  bool saveEvent() {
    // 验证输入
    if (_description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请添加日程描述'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800] 
            : Colors.grey[900],
        ),
      );
      return false;
    }

    final eventData = {
      'date': widget.selectedDate,
      'startTime': _startTime,
      'endTime': _endTime,
      'isAllDay': _isAllDay,
      'isImportant': _isImportant,
      'isRepeat': _isRepeat,
      'calendar': _calendar,
      'description': _description,
    };

    widget.onEventCreated(eventData);
    return true;
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('H:mm').format(dt);
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return '今天 周${_getWeekday(date.weekday)}';
    }
    return '${date.month}月${date.day}日 周${_getWeekday(date.weekday)}';
  }

  String _getWeekday(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部时间选择区域
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  // 时间选择器
                  Row(
                    children: [
                      // 开始时间
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (time != null) {
                              setState(() {
                                _startTime = time;
                                // 确保结束时间在开始时间之后
                                if (_endTime.hour < _startTime.hour || 
                                    (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
                                  _endTime = TimeOfDay(
                                    hour: (_startTime.hour + 1) % 24,
                                    minute: _startTime.minute,
                                  );
                                }
                              });
                            }
                          },
                          child: Column(
                            children: [
                              Text(
                                _formatTime(_startTime),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  color: theme.textTheme.headlineLarge?.color ?? (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              Text(
                                _formatDate(widget.selectedDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 箭头
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.arrow_forward,
                          color: theme.iconTheme.color?.withOpacity(0.4) ?? (isDark ? Colors.grey[600] : Colors.grey[400]),
                          size: 24,
                        ),
                      ),
                      
                      // 结束时间
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (time != null) {
                              setState(() {
                                _endTime = time;
                              });
                            }
                          },
                          child: Column(
                            children: [
                              Text(
                                _formatTime(_endTime),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  color: theme.textTheme.headlineLarge?.color ?? (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              Text(
                                _formatDate(widget.selectedDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
            
            // 选项列表
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // 全天选项
                  ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isAllDay ? theme.primaryColor : (theme.dividerColor),
                          width: 2,
                        ),
                        color: _isAllDay ? theme.primaryColor : Colors.transparent,
                      ),
                      child: _isAllDay 
                        ? Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                    ),
                    title: Text(
                      '全天',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    trailing: Switch(
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                        });
                      },
                      activeColor: theme.primaryColor,
                    ),
                    onTap: () {
                      setState(() {
                        _isAllDay = !_isAllDay;
                      });
                    },
                  ),
                  
                  // 重要选项
                  ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isImportant ? theme.primaryColor : theme.dividerColor,
                          width: 2,
                        ),
                        color: _isImportant ? theme.primaryColor : Colors.transparent,
                      ),
                      child: _isImportant 
                        ? Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                    ),
                    title: Text(
                      '重要',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isImportant = !_isImportant;
                      });
                    },
                  ),
                  
                  // 日程重复选项
                  ListTile(
                    leading: Icon(
                      Icons.repeat,
                      color: theme.iconTheme.color,
                      size: 24,
                    ),
                    title: Text(
                      '日程重复',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isRepeat = !_isRepeat;
                      });
                    },
                  ),
                  
                  // 我的日历选项
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: theme.iconTheme.color,
                      size: 24,
                    ),
                    title: Text(
                      '我的日历',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    onTap: () {
                      // 显示日历选择器
                    },
                  ),
                  
                  // 添加说明选项
                  ListTile(
                    leading: Icon(
                      Icons.edit_note,
                      color: theme.iconTheme.color,
                      size: 24,
                    ),
                    title: Text(
                      '添加说明',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    onTap: () {
                      _showDescriptionDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDescriptionDialog() {
    final controller = TextEditingController(text: _description);
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          '添加说明',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          decoration: InputDecoration(
            hintText: '请输入日程说明...',
            hintStyle: TextStyle(color: theme.hintColor),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _description = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text(
              '确定',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
} 