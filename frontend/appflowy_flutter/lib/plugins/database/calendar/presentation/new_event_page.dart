import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';

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
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isAllDay = false;
  bool _isImportant = false;
  bool _isRepeat = false;
  String _calendar = '我的日历';
  String _description = '';
  String _reminderOption = '无';

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
    
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
      'date': _startDate,
      'startTime': _startTime,
      'endTime': _endTime,
      'startDate': _startDate,
      'endDate': _endDate,
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

  // 构建全天日期选择器
  Widget _buildAllDayDatePicker(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _showDatePicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              _formatAllDayDate(_startDate),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: theme.textTheme.headlineLarge?.color ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '全天',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建时间区间选择器
  Widget _buildTimeRangePicker(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // 开始时间
        Expanded(
          child: GestureDetector(
            onTap: () => _showCustomTimePicker(isStartTime: true),
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
                  _formatDate(_startDate),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            Icons.arrow_forward,
            color: theme.iconTheme.color?.withOpacity(0.4) ?? (isDark ? Colors.grey[600] : Colors.grey[400]),
            size: 24,
          ),
        ),
        
        // 结束时间
        Expanded(
          child: GestureDetector(
            onTap: () => _showCustomTimePicker(isStartTime: false),
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
                  _formatDate(_endDate),
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
    );
  }

  // 格式化全天日期显示
  String _formatAllDayDate(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return '今天';
    }
    return '${date.month}月${date.day}日';
  }

  // 显示日期选择器
  Future<void> _showDatePicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _startDate = selectedDate;
        _endDate = selectedDate; // 全天模式下结束日期等于开始日期
      });
    }
  }

  // 显示自定义时间选择器
  Future<void> _showCustomTimePicker({
    required bool isStartTime,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: CustomTimePickerBottomSheet(
          initialDate: isStartTime ? _startDate : _endDate,
          initialTime: isStartTime ? _startTime : _endTime,
          title: isStartTime ? '开始时间' : '结束时间',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isStartTime) {
          _startDate = result['date'];
          _startTime = result['time'];
          // 确保结束时间在开始时间之后
          final startDateTime = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
          final endDateTime = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );
          
          if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
            _endDate = _startDate;
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endDate = result['date'];
          _endTime = result['time'];
        }
      });
    }
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
                  _isAllDay ? _buildAllDayDatePicker(theme, isDark) : _buildTimeRangePicker(theme, isDark),
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
                    leading: FlowySvg(
                      FlowySvgs.time_m,
                      color: theme.iconTheme.color,
                      size: const Size.square(24),
                    ),
                    title: Text(
                      '全天',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    trailing: Toggle(
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                          if (_isAllDay) {
                            // 切换到全天模式时，设置结束日期等于开始日期
                            _endDate = _startDate;
                            // 设置默认时间为全天
                            _startTime = const TimeOfDay(hour: 0, minute: 0);
                            _endTime = const TimeOfDay(hour: 23, minute: 59);
                          }
                        });
                      },
                      style: const ToggleStyle.mobile(),
                      padding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      setState(() {
                        _isAllDay = !_isAllDay;
                      });
                    },
                  ),
                  
                  // 准时选项
                  ListTile(
                    leading: FlowySvg(
                      FlowySvgs.alarm_m,
                      color: theme.iconTheme.color,
                      size: const Size.square(24),
                    ),
                    title: Text(
                      _reminderOption,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    onTap: () {
                      _showReminderDialog();
                    },
                  ),
                  
                  // 日程重复选项
                  ListTile(
                    leading: FlowySvg(
                      FlowySvgs.repeat_m,
                      color: theme.iconTheme.color,
                      size: const Size.square(24),
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
                   leading: FlowySvg(
                     FlowySvgs.group_m,
                     color: theme.iconTheme.color,
                     size: const Size.square(24),
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
                   leading: FlowySvg(
                     FlowySvgs.edit_m,
                     color: theme.iconTheme.color,
                     size: const Size.square(24),
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

  void _showReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 阻止点击外部区域关闭弹窗
      builder: (BuildContext context) {
        return ReminderSelectionDialog(
          currentOption: _reminderOption,
          onSave: (selectedOption) {
            setState(() {
              _reminderOption = selectedOption;
            });
          },
        );
      },
    );
  }
}

// 自定义时间选择器底部弹窗
class CustomTimePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay initialTime;
  final String title;

  const CustomTimePickerBottomSheet({
    Key? key,
    required this.initialDate,
    required this.initialTime,
    required this.title,
  }) : super(key: key);

  @override
  State<CustomTimePickerBottomSheet> createState() => _CustomTimePickerBottomSheetState();
}

class _CustomTimePickerBottomSheetState extends State<CustomTimePickerBottomSheet> {
  late DateTime selectedDate;
  late int selectedHour;
  late int selectedMinute;
  late DateTime currentMonth;
  
  final FixedExtentScrollController hourController = FixedExtentScrollController();
  final FixedExtentScrollController minuteController = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
    currentMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    
    // 设置初始滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hourController.jumpToItem(selectedHour);
      minuteController.jumpToItem(selectedMinute);
    });
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  // 获取月份的天数
  int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // 获取月份第一天是星期几（0=周日，1=周一，...，6=周六）
  int getFirstDayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  // 生成日历网格
  Widget buildCalendar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final daysInMonth = getDaysInMonth(currentMonth);
    final firstDayOfWeek = getFirstDayOfWeek(currentMonth);
    final today = DateTime.now();
    
    return Column(
      children: [
        // 月份导航
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                  });
                },
                icon: Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
              ),
              Text(
                '${currentMonth.year}年${currentMonth.month}月',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                  });
                },
                icon: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        
        // 星期标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              return Expanded(
                child: Container(
                  height: 25,
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // 日历网格
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42, // 6周 x 7天
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayOfWeek + 1;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Container(); // 空白日期
              }
              
              final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
              final isSelected = date.year == selectedDate.year && 
                                date.month == selectedDate.month && 
                                date.day == selectedDate.day;
              final isToday = date.year == today.year && 
                             date.month == today.month && 
                             date.day == today.day;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                      ? const Color(0xFFFF6B35)
                      : isToday
                        ? (isDark ? Colors.grey[700] : Colors.grey[200])
                        : Colors.transparent,
                    border: isToday && !isSelected
                      ? Border.all(
                          color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                          width: 1,
                        )
                      : null,
                  ),
                  child: Center(
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                        fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 700, // 进一步增加高度以容纳日历
      width: 400,  // 增加宽度给日历更多空间
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头部
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Stack(
              children: [
                // 居中的标题
                Center(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                // 右侧的确认按钮
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'date': selectedDate,
                            'time': TimeOfDay(hour: selectedHour, minute: selectedMinute),
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          '确认',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 日历和时间选择器
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 日历部分
                  Expanded(
                    flex: 4,
                    child: buildCalendar(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 时间标签
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '时间',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 时间选择器
                  SizedBox(
                    height: 140,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // 小时选择器
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: 30,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '时',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: hourController,
                                    itemExtent: 28,
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedHour = index;
                                      });
                                    },
                                    children: List.generate(24, (index) {
                                      return Center(
                                        child: Text(
                                          index.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 分隔线
                          Container(
                            width: 1,
                            height: 60,
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                          ),
                          
                          // 分钟选择器
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: 30,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '分',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: minuteController,
                                    itemExtent: 28,
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedMinute = index;
                                      });
                                    },
                                    children: List.generate(60, (index) {
                                      return Center(
                                        child: Text(
                                          index.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 

// 提醒选择弹窗
class ReminderSelectionDialog extends StatefulWidget {
  final String currentOption;
  final Function(String) onSave;

  const ReminderSelectionDialog({
    Key? key,
    required this.currentOption,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ReminderSelectionDialog> createState() => _ReminderSelectionDialogState();
}

class _ReminderSelectionDialogState extends State<ReminderSelectionDialog> {
  late String _tempSelectedOption;

  @override
  void initState() {
    super.initState();
    _tempSelectedOption = widget.currentOption; // 使用当前选项作为初始值
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      '无',
      '准时',
      '提前5分钟',
      '提前30分钟',
      '提前1个小时',
      '提前1天',
      '自定义'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // 放大圆角
      ),
      child: Container(
        width: 280, // 放大宽度
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // 放大内边距
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 38, // 放大标题栏高度
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 28, // 放大关闭按钮区域宽度
                    child: GestureDetector(
                      onTap: () {
                        // 点击关闭按钮，不保存更改
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Icon(Icons.close, size: 20), // 放大图标
                    ),
                  ),
                  const Text(
                    '提醒时间',
                    style: TextStyle(
                      fontSize: 16, // 放大标题字体
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9B73),
                      borderRadius: BorderRadius.circular(6), // 放大圆角
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // 点击保存按钮，保存选择并关闭
                        widget.onSave(_tempSelectedOption);
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 放大内边距
                        child: Text(
                          '保存',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14, // 放大按钮字体
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6), // 放大间距
            ...options.map((option) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tempSelectedOption = option; // 只更新临时状态
                  });
                },
                child: Container(
                  height: 34, // 放大每个选项的高度
                  width: double.infinity,
                  padding: EdgeInsets.zero, // 移除水平内边距
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28, // 与关闭按钮区域同宽，确保对齐
                        child: Transform.scale(
                          scale: 0.8, // 放大单选按钮
                          child: Radio<String>(
                            value: option,
                            groupValue: _tempSelectedOption, // 使用临时状态
                            onChanged: (value) {
                              setState(() {
                                _tempSelectedOption = value!; // 只更新临时状态
                              });
                            },
                            activeColor: const Color(0xFFFF9B73),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4), // 放大间距
                      Text(
                        option,
                        style: const TextStyle(
                          fontSize: 14, // 放大选项字体
                          height: 1.2, // 放大行高
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 