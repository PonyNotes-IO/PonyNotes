import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewEventPage extends StatefulWidget {
  const NewEventPage({
    super.key,
    required this.selectedDate,
    required this.onEventCreated,
  });

  final DateTime selectedDate;
  final Function(String title, DateTime date, TimeOfDay time, String? description) onEventCreated;

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  ReminderOption _selectedReminderOption = ReminderOption.none;
  bool _includeTime = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = widget.selectedDate;
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 页面标题
                Row(
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FlowyText.semibold(
                        LocaleKeys.calendar_newEventButtonTooltip.tr(),
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                                 // 事件标题
                 FlowyText.medium(
                   LocaleKeys.grid_row_textPlaceholder.tr(),
                   fontSize: 16,
                 ),
                 const SizedBox(height: 12),
                 FlowyTextField(
                   controller: _titleController,
                   hintText: LocaleKeys.calendar_defaultNewCalendarTitle.tr(),
                   autoFocus: true,
                 ),
                 const SizedBox(height: 24),
                 
                 // 日期时间选择
                 FlowyText.medium(
                   LocaleKeys.grid_field_dateFieldName.tr(),
                   fontSize: 16,
                 ),
                 const SizedBox(height: 12),
                 _buildDateTimeSelector(),
                 const SizedBox(height: 24),
                 
                 // 提醒设置
                 FlowyText.medium(
                   LocaleKeys.datePicker_reminderLabel.tr(),
                   fontSize: 16,
                 ),
                 const SizedBox(height: 12),
                 ReminderSelector(
                   mutex: null,
                   selectedOption: _selectedReminderOption,
                   onOptionSelected: (option) {
                     setState(() {
                       _selectedReminderOption = option;
                     });
                   },
                   timeFormat: TimeFormatPB.TwentyFourHour,
                   hasTime: _includeTime,
                 ),
                 const SizedBox(height: 24),
                 
                 // 描述
                 FlowyText.medium(
                   LocaleKeys.document_textBlock_placeholder.tr(),
                   fontSize: 16,
                 ),
                const SizedBox(height: 12),
                FlowyTextField(
                  controller: _descriptionController,
                  hintText: LocaleKeys.document_textBlock_placeholder.tr(),
                  maxLines: 6,
                ),
                const SizedBox(height: 32),
                
                // 按钮区域
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FlowyTextButton(
                      LocaleKeys.button_cancel.tr(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      onPressed: () {
                        // 关闭当前标签页
                        getIt<TabsBloc>().add(const TabsEvent.closeCurrentTab());
                      },
                    ),
                    const SizedBox(width: 16),
                    FlowyTextButton(
                      LocaleKeys.button_create.tr(),
                      fontColor: Colors.white,
                      fillColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      onPressed: _createEvent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 日期选择
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('yyyy年MM月dd日').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              FlowyTextButton(
                '选择日期',
                fontSize: 14,
                fontColor: Theme.of(context).colorScheme.primary,
                onPressed: _selectDate,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 时间选择开关
          Row(
            children: [
              Icon(Icons.access_time, size: 20, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '包含时间',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Switch(
                value: _includeTime,
                onChanged: (value) {
                  setState(() {
                    _includeTime = value;
                  });
                },
              ),
            ],
          ),
          // 时间选择
          if (_includeTime) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    _selectedTime.format(context),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                FlowyTextButton(
                  '选择时间',
                  fontSize: 14,
                  fontColor: Theme.of(context).colorScheme.primary,
                  onPressed: _selectTime,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _createEvent() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('标题不能为空'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    
    widget.onEventCreated(
      title,
      _selectedDate,
      _includeTime ? _selectedTime : const TimeOfDay(hour: 9, minute: 0),
      description.isNotEmpty ? description : null,
    );
  }
} 