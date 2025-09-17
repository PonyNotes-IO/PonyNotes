import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/plugins/homepage/application/todo_models.dart';
import 'package:appflowy/plugins/homepage/application/todo_service.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 快速创建事件/待办的组件
/// 直接使用TodoService创建待办事项并保存到数据库
class QuickEventCreator extends StatefulWidget {
  final Function(TodoItem)? onEventCreated;

  const QuickEventCreator({
    super.key,
    this.onEventCreated,
  });

  @override
  State<QuickEventCreator> createState() => _QuickEventCreatorState();
}

class _QuickEventCreatorState extends State<QuickEventCreator> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAllDay = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部图标和标题
        _buildHeader(),
        const SizedBox(height: 20),
        
        // 标题输入
        _buildTitleInput(),
        const SizedBox(height: 12),
        
        // 时间选择
        _buildTimeSelector(),
        const SizedBox(height: 12),
        
        // 全天开关
        _buildAllDayToggle(),
        const SizedBox(height: 20),
        
        // 创建按钮
        _buildCreateButton(),
        
        const Spacer(),
        
        // 底部链接
        _buildCalendarLink(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 58,
          height: 51,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8D69),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_today,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "快速创建",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "标题",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "输入待办事项...",
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFE9E9E9),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFE9E9E9),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFFF8D69),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "时间",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // 日期选择
            Expanded(
              child: InkWell(
                onTap: _isAllDay ? null : _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE9E9E9),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: _isAllDay ? Colors.grey[50] : Colors.white,
                  ),
                  child: Text(
                    DateFormat('MM/dd').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: _isAllDay ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 时间选择
            Expanded(
              child: InkWell(
                onTap: _isAllDay ? null : _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE9E9E9),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: _isAllDay ? Colors.grey[50] : Colors.white,
                  ),
                  child: Text(
                    _isAllDay ? "全天" : _selectedTime.format(context),
                    style: TextStyle(
                      fontSize: 13,
                      color: _isAllDay ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllDayToggle() {
    return Row(
      children: [
        Switch.adaptive(
          value: _isAllDay,
          onChanged: (value) {
            setState(() {
              _isAllDay = value;
            });
          },
          activeColor: const Color(0xFFFF8D69),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 8),
        const Text(
          "全天",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8D69),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        child: _isCreating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "创建待办",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildCalendarLink() {
    return InkWell(
      onTap: _openCalendar,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: const Color(0xFFFF8D69),
            ),
            const SizedBox(width: 4),
            const Text(
              "链接我的日历 →",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF8D69),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFFF8D69),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCalendar() {
    try {
      // 创建日历插件
      final calendarPlugin = makePlugin(
        pluginType: PluginType.calendar,
        data: null,
      );

      // 在新标签页中打开日历
      context.read<TabsBloc>().add(
        TabsEvent.openPlugin(plugin: calendarPlugin),
      );

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("正在打开日历..."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("打开日历失败: $e"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8D69),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8D69),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("请输入待办事项标题"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // 构建 TodoItem 对象
      final dueDate = _isAllDay 
          ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
          : DateTime(
              _selectedDate.year,
              _selectedDate.month, 
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

      final todoItem = TodoItem(
        id: '', // 会在 TodoService.addTodo 中自动生成
        title: _titleController.text.trim(),
        description: '',
        priority: TodoPriority.medium,
        dueDate: dueDate,
        isAllDay: _isAllDay,
        source: TodoSource.manual,
        createdAt: DateTime.now(),
      );

      // 实际保存到数据库
      await TodoService.instance.addTodo(todoItem);
      
      print('待办事项已保存: ${todoItem.title}, 截止时间: ${todoItem.dueDate}');

      // 清空输入
      _titleController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _isAllDay = false;
      });

      // 通知父组件
      widget.onEventCreated?.call(todoItem);

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("待办事项创建成功"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("创建失败: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
