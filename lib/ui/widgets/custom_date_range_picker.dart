import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

/// App-styled replacement for Flutter's default [showDateRangePicker],
/// wrapped in [CustomDialog] so it matches every other modal in the app.
Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return CustomDialog(
    title: AppLocalizations.of(context)!.selectDateRange,
    width: 380,
    child: _DateRangePickerContent(
      initialRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  ).show<DateTimeRange?>(context);
}

class _DateRangePickerContent extends StatefulWidget {
  const _DateRangePickerContent({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DateRangePickerContent> createState() =>
      _DateRangePickerContentState();
}

class _DateRangePickerContentState extends State<_DateRangePickerContent> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialRange?.start;
    _rangeEnd = widget.initialRange?.end;
    _focusedDay = _rangeStart ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final canSave = _rangeStart != null && _rangeEnd != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          canSave
              ? '${_formatDate(context, _rangeStart!)} – ${_formatDate(context, _rangeEnd!)}'
              : l.selectDateRangeHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.descriptionColor,
          ),
        ),
        const SizedBox(height: 12),
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
            firstDay: widget.firstDate,
            lastDay: widget.lastDate,
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: locale.toLanguageTag(),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.textColor,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: colorScheme.textColor,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.textColor,
              ),
            ),
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _rangeStart = start;
                _rangeEnd = end;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: colorScheme.calendarBg?.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              todayTextStyle: theme.textTheme.bodySmall!.copyWith(
                color: colorScheme.calendarTextBg,
                fontWeight: FontWeight.w700,
              ),
              rangeStartDecoration: BoxDecoration(
                color: colorScheme.primaryColor,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: colorScheme.primaryColor,
                shape: BoxShape.circle,
              ),
              rangeStartTextStyle: theme.textTheme.bodySmall!.copyWith(
                color: colorScheme.textInvertedColor,
                fontWeight: FontWeight.w700,
              ),
              rangeEndTextStyle: theme.textTheme.bodySmall!.copyWith(
                color: colorScheme.textInvertedColor,
                fontWeight: FontWeight.w700,
              ),
              withinRangeDecoration: BoxDecoration(
                color: colorScheme.primaryColor?.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              withinRangeTextStyle: theme.textTheme.bodySmall!.copyWith(
                color: colorScheme.calendarTextBg,
                fontWeight: FontWeight.w600,
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: canSave
                  ? () => Navigator.of(context).pop(
                      DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
                    )
                  : null,
              child: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}
