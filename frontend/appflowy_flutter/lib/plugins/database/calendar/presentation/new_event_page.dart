import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import '../models/schedule_model.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import '../../application/row/row_service.dart';
import '../../application/field/field_info.dart';

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
  
  // 使用ScheduleModel来管理日程
  late ScheduleModel _scheduleModel;

  @override
  void initState() {
    super.initState();
    _scheduleModel = ScheduleModel();
    
    // 初始化日历视图
    _initializeCalendarView();
    
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
    
    // 设置保存回调
    if (widget.onSaveRequested != null) {
      widget.onSaveRequested!(saveEvent);
    }
  }

  // 初始化日历视图
  Future<void> _initializeCalendarView() async {
    print('NewEventPage: 开始初始化日历视图');
    try {
      final success = await _scheduleModel.initializeCalendarView();
      if (success) {
        print('NewEventPage: 日历视图初始化成功，viewId: ${_scheduleModel.currentViewId}');
      } else {
        print('NewEventPage: 日历视图初始化失败');
        // 在界面上显示警告，但不阻止用户继续操作
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ 数据库连接失败，日程将无法保存'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('NewEventPage: 初始化日历视图时发生异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 初始化失败: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scheduleModel.dispose();
    super.dispose();
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

    // 构建开始和结束时间进行验证
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

    // 验证时间合法性
    final now = DateTime.now();
    
    // 检查时间是否在1970年之后
    if (startDateTime.year < 1970 || endDateTime.year < 1970) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 时间设置无效，请选择有效的时间'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }

    // 检查开始时间是否在过去（允许用户设置过去的日程，但给出警告）
    if (startDateTime.isBefore(now.subtract(Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ 开始时间在过去，请确认时间设置'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      // 不阻止保存，但给出警告
    }

    // 检查结束时间是否在开始时间之后
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 结束时间必须在开始时间之后'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }

    // 检查日程时长是否合理（不能超过30天）
    final duration = endDateTime.difference(startDateTime);
    if (duration.inDays > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ 日程时长超过30天，请确认时间设置'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      // 不阻止保存，但给出警告
    }

    // 异步保存日程
    _saveEventAsync();
    return true;
  }

  Future<void> _saveEventAsync() async {
    print('开始保存日程...');
    
    try {
      // 构建开始和结束时间
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

      print('日程信息: 标题=${_description}, 开始时间=$startDateTime, 结束时间=$endDateTime');

      // 检查widget是否仍然挂载
      if (!mounted) {
        print('Widget已卸载，取消保存操作');
        return;
      }

      // 检查ScheduleModel的状态
      print('当前ScheduleModel状态: viewId=${_scheduleModel.currentViewId}');
      
      if (_scheduleModel.currentViewId == null) {
        print('警告: ScheduleModel 没有设置 viewId，尝试初始化日历视图');
        
        // 尝试初始化日历视图
        final initialized = await _scheduleModel.initializeCalendarView();
        if (!initialized) {
          throw Exception('无法初始化日历视图，请检查 AppFlowy 数据库连接');
        }
        print('日历视图初始化成功，viewId: ${_scheduleModel.currentViewId}');
      }

      // 使用ScheduleModel创建日程
      print('调用 createSchedule 方法...');
      final resultId = await _scheduleModel.createSchedule(
        title: _description.isNotEmpty ? _description : '无标题日程',
        description: _description,
        startTime: startDateTime,
        endTime: endDateTime,
      );

      print('createSchedule 结果: $resultId');

      // 再次检查widget是否仍然挂载
      if (!mounted) {
        print('Widget已卸载，取消处理结果');
        return;
      }

      // 创建成功
      if (resultId != null) {
        print('日程创建成功，ID: $resultId');
        
        // 创建成功，调用回调
        final eventData = {
          'id': resultId,
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
        
        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 日程创建成功！'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('创建日程失败：返回的ID为空');
      }
    } catch (e, stackTrace) {
      // 异常处理
      print('创建日程时发生异常: $e');
      print('堆栈跟踪: $stackTrace');
      
      if (mounted) {
        String errorMessage = '创建日程失败';
        String detailedError = e.toString();
        
        // 根据不同类型的错误提供不同的提示
        if (e.toString().contains('数据库未连接')) {
          errorMessage = '数据库连接失败';
          detailedError = '请确保 AppFlowy 数据库正在运行';
        } else if (e.toString().contains('初始化')) {
          errorMessage = '日历视图初始化失败';
          detailedError = '请检查数据库连接和权限设置';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: '详情',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text('错误详情'),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            detailedError,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '故障排除建议:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. 检查 AppFlowy 应用是否正在运行\n'
                            '2. 确认数据库服务状态正常\n'
                            '3. 检查网络连接\n'
                            '4. 重启应用程序\n'
                            '5. 查看控制台日志了解详细信息',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (detailedError.length > 100) ...[
                            SizedBox(height: 16),
                            Text(
                              '完整错误信息:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('关闭'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 可以在这里添加重试逻辑
                          _saveEventAsync();
                        },
                        child: Text('重试'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
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
      child: Row(
        children: [
          // 左侧占位，保持与时间区间选择器布局一致
          Expanded(
            child: Container(), // 空容器保持对称
          ),
          
          // 中间显示内容，居中展示
          Column(
            children: [
              Text(
                _formatAllDayDate(_startDate),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: theme.textTheme.headlineLarge?.color ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
              Text(
                '全天',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
          
          // 右侧占位，保持布局对称
          Expanded(
            child: Container(), // 空容器保持对称
          ),
        ],
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

  // 显示日期选择器（使用自定义时间选择器，但只显示日历部分）
  Future<void> _showDatePicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // 阻止点击外部区域关闭弹窗
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: CustomTimePickerBottomSheet(
          initialDate: _startDate,
          initialTime: _startTime,
          title: '选择日期',
          showTimePicker: false, // 只显示日历，不显示时间选择器
        ),
      ),
    );

    if (result != null) {
      final selectedDate = result['date'] as DateTime;
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
      barrierDismissible: false, // 阻止点击外部区域关闭弹窗
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: CustomTimePickerBottomSheet(
          initialDate: isStartTime ? _startDate : _endDate,
          initialTime: isStartTime ? _startTime : _endTime,
          title: isStartTime ? '开始时间' : '结束时间',
          showTimePicker: !_isAllDay, // 根据是否勾选全天决定是否显示时间选择器
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
          // 确保开始时间在结束时间之前
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
          
          if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
            _startDate = _endDate;
            _startTime = TimeOfDay(
              hour: (_endTime.hour - 1 + 24) % 24,
              minute: _endTime.minute,
            );
          }
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
      barrierDismissible: false, // 防止误触关闭
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 更大的圆角
        ),
        child: Container(
          width: 400, // 固定宽度
          padding: const EdgeInsets.all(24), // 增加内边距
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '添加说明',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 输入框
              TextField(
                controller: controller,
                maxLines: 4, // 增加行数
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                decoration: InputDecoration(
                  hintText: '请输入日程说明...',
                  hintStyle: TextStyle(
                    color: theme.hintColor,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  hoverColor: Colors.transparent, // 禁用悬停时的背景颜色变化
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                autofocus: true, // 自动聚焦
              ),
              
              const SizedBox(height: 24),
              
              // 按钮栏
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 取消按钮
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 确定按钮
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _description = controller.text;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '确定',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
  final bool showTimePicker; // 新增参数控制是否显示时间选择器

  const CustomTimePickerBottomSheet({
    Key? key,
    required this.initialDate,
    required this.initialTime,
    required this.title,
    this.showTimePicker = true, // 默认显示时间选择器
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
      height: widget.showTimePicker ? 700 : 500, // 根据是否显示时间选择器调整高度
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
                // 左上角的关闭按钮
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context); // 关闭弹窗，不返回任何数据
                      },
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                      ),
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
                    flex: widget.showTimePicker ? 4 : 1, // 根据是否显示时间选择器调整比例
                    child: buildCalendar(),
                  ),
                  
                  // 只有在显示时间选择器时才显示时间相关部分
                  if (widget.showTimePicker) ...[
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
        borderRadius: BorderRadius.circular(16), // 更大的圆角
      ),
      child: Container(
        width: 320, // 增加宽度
        padding: const EdgeInsets.all(24), // 增加内边距
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.alarm,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '提醒时间',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                // 关闭按钮
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 选项列表
            ...options.map((option) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _tempSelectedOption = option;
                      });
                    },
                    child: Container(
                      height: 48, // 增加选项高度
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: option,
                            groupValue: _tempSelectedOption,
                            onChanged: (value) {
                              setState(() {
                                _tempSelectedOption = value!;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // 按钮栏
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 取消按钮
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 保存按钮
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(_tempSelectedOption);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '保存',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 