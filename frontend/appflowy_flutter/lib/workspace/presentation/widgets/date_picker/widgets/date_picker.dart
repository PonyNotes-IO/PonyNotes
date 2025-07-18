import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

final kFirstDay = DateTime.utc(1970);
final kLastDay = DateTime.utc(2100);

class DatePicker extends StatefulWidget {
  const DatePicker({
    super.key,
    required this.isRange,
    this.calendarFormat = CalendarFormat.month,
    this.startDay,
    this.endDay,
    this.selectedDay,
    required this.focusedDay,
    this.onDaySelected,
    this.onRangeSelected,
    this.onCalendarCreated,
    this.onPageChanged,
  });

  final bool isRange;
  final CalendarFormat calendarFormat;

  final DateTime? startDay;
  final DateTime? endDay;
  final DateTime? selectedDay;

  final DateTime focusedDay;

  final void Function(
    DateTime selectedDay,
    DateTime focusedDay,
  )? onDaySelected;

  final void Function(
    DateTime? start,
    DateTime? end,
    DateTime focusedDay,
  )? onRangeSelected;

  final void Function(PageController pageController)? onCalendarCreated;

  final void Function(DateTime focusedDay)? onPageChanged;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  late CalendarFormat _calendarFormat = widget.calendarFormat;
  late final AFPopoverController _popoverController;

  @override
  void initState() {
    super.initState();
    _popoverController = AFPopoverController();
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final boxDecoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      shape: BoxShape.circle,
    );

    final calendarStyle = UniversalPlatform.isMobile
        ? _CalendarStyle.mobile(
            dowTextStyle: textStyle.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: 14.0,
            ),
          )
        : _CalendarStyle.desktop(
            dowTextStyle: AFThemeExtension.of(context).caption,
            selectedColor: Theme.of(context).colorScheme.primary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // 自定义头部
          _buildCustomHeader(context, widget.focusedDay),
          SizedBox(height: 8),
          // 日历主体
          Expanded(
            child: TableCalendar(
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: widget.focusedDay,
              rowHeight: calendarStyle.rowHeight,
              calendarFormat: _calendarFormat,
              daysOfWeekHeight: calendarStyle.dowHeight,
              rangeSelectionMode: widget.isRange
                  ? RangeSelectionMode.enforced
                  : RangeSelectionMode.disabled,
              rangeStartDay: widget.isRange ? widget.startDay : null,
              rangeEndDay: widget.isRange ? widget.endDay : null,
              availableGestures: calendarStyle.availableGestures,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              onCalendarCreated: widget.onCalendarCreated,
              headerVisible: false, // 隐藏默认头部
              headerStyle: calendarStyle.headerStyle,
              calendarStyle: CalendarStyle(
                cellMargin: const EdgeInsets.all(3.5),
                defaultDecoration: boxDecoration,
                selectedDecoration: boxDecoration.copyWith(
                  color: calendarStyle.selectedColor,
                ),
                todayDecoration: boxDecoration.copyWith(
                  color: Colors.transparent,
                  border: Border.all(color: calendarStyle.selectedColor),
                ),
                weekendDecoration: boxDecoration,
                outsideDecoration: boxDecoration,
                rangeStartDecoration: boxDecoration.copyWith(
                  color: calendarStyle.selectedColor,
                ),
                rangeEndDecoration: boxDecoration.copyWith(
                  color: calendarStyle.selectedColor,
                ),
                defaultTextStyle: textStyle,
                weekendTextStyle: textStyle,
                selectedTextStyle: textStyle.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
                rangeStartTextStyle: textStyle.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
                rangeEndTextStyle: textStyle.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
                todayTextStyle: textStyle,
                outsideTextStyle: textStyle.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
                rangeHighlightColor:
                    Theme.of(context).colorScheme.secondaryContainer,
              ),
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final locale = context.locale.toLanguageTag();
                  final label = DateFormat.E(locale).format(day);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Center(
                      child: Text(label, style: calendarStyle.dowTextStyle),
                    ),
                  );
                },
              ),
              selectedDayPredicate: (day) =>
                  widget.isRange ? false : isSameDay(widget.selectedDay, day),
              onFormatChanged: (calendarFormat) =>
                  setState(() => _calendarFormat = calendarFormat),
              onPageChanged: (focusedDay) {
                widget.onPageChanged?.call(focusedDay);
              },
              onDaySelected: widget.onDaySelected,
              onRangeSelected: widget.onRangeSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, DateTime focusedDay) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          // 顶部按钮行
          Row(
            children: [
              Spacer(), // 将按钮推到右边
              // 加号按钮
              AFPopover(
                controller: _popoverController,
                padding: EdgeInsets.zero,
                anchor: AFAnchor(
                  childAlignment: Alignment.topCenter,
                  overlayAlignment: Alignment.bottomCenter,
                  offset: const Offset(0, 8),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                popover: (context) => _buildDropdownMenu(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () {
                      _popoverController.toggle();
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // 更多选项按钮
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  size: 20,
                ),
                onPressed: () {
                  // TODO: 添加按钮点击逻辑
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // 月份导航行
          Row(
            children: [
              // 月份信息在左边
              Expanded(
                child: Text(
                  '${focusedDay.year}年${focusedDay.month}月',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 导航按钮在右边
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 20),
                    onPressed: () {
                      // 计算上个月
                      final previousMonth = DateTime(
                        focusedDay.year,
                        focusedDay.month - 1,
                      );
                      widget.onPageChanged?.call(previousMonth);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, size: 20),
                    onPressed: () {
                      // 计算下个月
                      final nextMonth = DateTime(
                        focusedDay.year,
                        focusedDay.month + 1,
                      );
                      widget.onPageChanged?.call(nextMonth);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownMenu(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 新建日记页按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              onTap: () {
                _popoverController.hide();
                // TODO: 处理新建日记页
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.note_add,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '新建日记页',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 分割线
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          // 新建日程按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              onTap: () {
                _popoverController.hide();
                // TODO: 处理新建日程
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '新建日程',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarStyle {
  _CalendarStyle.desktop({
    required this.selectedColor,
    required this.dowTextStyle,
  })  : rowHeight = 33,
        dowHeight = 35,
        headerVisible = false,
        headerStyle = const HeaderStyle(),
        availableGestures = AvailableGestures.horizontalSwipe;

  _CalendarStyle.mobile({required this.dowTextStyle})
      : rowHeight = 48,
        dowHeight = 48,
        headerVisible = false,
        headerStyle = const HeaderStyle(),
        selectedColor = const Color(0xFF00BCF0),
        availableGestures = AvailableGestures.horizontalSwipe;

  _CalendarStyle({
    required this.rowHeight,
    required this.dowHeight,
    required this.headerVisible,
    required this.headerStyle,
    required this.dowTextStyle,
    required this.selectedColor,
    required this.availableGestures,
  });

  final double rowHeight;
  final double dowHeight;
  final bool headerVisible;
  final HeaderStyle headerStyle;
  final TextStyle dowTextStyle;
  final Color selectedColor;
  final AvailableGestures availableGestures;
}
