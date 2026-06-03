import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:table_calendar/table_calendar.dart';

class ClockingDateSelector extends StatefulWidget {
  const ClockingDateSelector({
    super.key,
    required this.selectedDate,
    required this.calendarFormat,
    required this.onSelectedDateChanged,
    required this.onFormatChanged,
  });

  final DateTime selectedDate;
  final CalendarFormat calendarFormat;
  final ValueChanged<DateTime> onSelectedDateChanged;
  final ValueChanged<CalendarFormat> onFormatChanged;

  static final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  static final DateTime _lastDay = DateTime.utc(2035, 12, 31);

  @override
  State<ClockingDateSelector> createState() => _ClockingDateSelectorState();
}

class _ClockingDateSelectorState extends State<ClockingDateSelector> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = _normalizeDate(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant ClockingDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _focusedDay = _normalizeDate(widget.selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final today = _normalizeDate(DateTime.now());
    final isTodaySelected = _isSameDay(widget.selectedDate, today);
    final dateLabel = DateFormat.yMMMMEEEEd(
      locale.toLanguageTag(),
    ).format(widget.selectedDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.clockingDateLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.descriptionColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _capitalize(dateLabel),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.iconLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<CalendarFormat>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<CalendarFormat>(
                    value: CalendarFormat.week,
                    label: Text(localization.calendarWeek),
                  ),
                  ButtonSegment<CalendarFormat>(
                    value: CalendarFormat.month,
                    label: Text(localization.calendarMonth),
                  ),
                ],
                selected: {widget.calendarFormat},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  widget.onFormatChanged(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: isTodaySelected
                  ? null
                  : () {
                      setState(() {
                        _focusedDay = today;
                      });
                      widget.onSelectedDateChanged(today);
                    },
              icon: const Icon(Icons.today_rounded, size: 18),
              label: Text(localization.today),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: <PointerDeviceKind>{
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            child: TableCalendar<void>(
              firstDay: ClockingDateSelector._firstDay,
              lastDay: ClockingDateSelector._lastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(day, widget.selectedDate),
              currentDay: DateTime.now(),
              calendarFormat: widget.calendarFormat,
              availableGestures: AvailableGestures.all,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerVisible: false,
              locale: locale.toLanguageTag(),
              availableCalendarFormats: const {
                CalendarFormat.week: 'week',
                CalendarFormat.month: 'month',
              },
              onFormatChanged: widget.onFormatChanged,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = _normalizeDate(focusedDay);
                });
                widget.onSelectedDateChanged(
                  DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  ),
                );
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = _normalizeDate(focusedDay);
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible:
                    widget.calendarFormat == CalendarFormat.month,
                todayDecoration: BoxDecoration(
                  color: colorScheme.calendarBg?.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: theme.textTheme.bodySmall!.copyWith(
                  color: colorScheme.textInvertedColor,
                  fontWeight: FontWeight.w700,
                ),
                todayTextStyle: theme.textTheme.bodySmall!.copyWith(
                  color: colorScheme.calendarTextBg,
                  fontWeight: FontWeight.w700,
                ),
                defaultTextStyle: theme.textTheme.bodySmall!.copyWith(
                  color: colorScheme.calendarTextBg,
                  fontWeight: FontWeight.w600,
                ),
                weekendTextStyle: theme.textTheme.bodySmall!.copyWith(
                  color: colorScheme.calendarTextWeekBg,
                  fontWeight: FontWeight.w600,
                ),
                outsideTextStyle: theme.textTheme.bodySmall!.copyWith(
                  color: colorScheme.descriptionColor,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.labelSmall!.copyWith(
                  color: colorScheme.descriptionColor,
                  fontWeight: FontWeight.w700,
                ),
                weekendStyle: theme.textTheme.labelSmall!.copyWith(
                  color: colorScheme.descriptionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
