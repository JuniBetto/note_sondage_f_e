import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/ui/task_density_scope.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_timeline_view.dart'
    show mondayOfWeek;
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';
import 'package:note_sondage/ui/widgets/custom_date_range_picker.dart';

const _kCalendarStartHour = 0;
const _kCalendarEndHour = 24;
// The grid spans the full day so no task/event is ever clipped out, but the
// view still opens scrolled to this hour since most items fall in typical
// working hours.
const _kCalendarDefaultScrollHour = 7;
const _kPixelsPerHour = 64.0;
const _kCalendarCompactBreakpoint = 760.0;

enum _CalendarViewMode { day, week, month, range }

/// Time-of-day calendar with an explicit Day / Week / Month switcher —
/// Day and Week render the hour-grid agenda (single day or full week);
/// Month renders a classic month grid with per-day task chips. Complements
/// [TaskTimelineView] (multi-day duration bars) by showing tasks positioned
/// at their actual time of day.
class TaskCalendarView extends StatefulWidget {
  const TaskCalendarView({
    super.key,
    required this.tasks,
    required this.weekStart,
    required this.onWeekStartChanged,
    required this.selectedTaskId,
    required this.onTaskTap,
    this.assigneeAvatarUrlByUserId = const <String, String>{},
  });

  final List<TaskEntity> tasks;
  final DateTime weekStart;
  final ValueChanged<DateTime> onWeekStartChanged;
  final String? selectedTaskId;
  final ValueChanged<TaskEntity> onTaskTap;
  final Map<String, String> assigneeAvatarUrlByUserId;

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  late DateTime _focusedDay;
  late DateTime _focusedMonth;
  // null until the user explicitly picks a mode: the initial mode still
  // follows screen width (day on narrow, week on wide), but from then on
  // it's fully under the user's control via the Day/Week/Month selector.
  _CalendarViewMode? _viewMode;
  DateTimeRange? _customRange;
  final ScrollController _hourGridScrollController = ScrollController(
    initialScrollOffset: _kCalendarDefaultScrollHour * _kPixelsPerHour,
  );

  List<DateTime> get _days =>
      List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));

  List<DateTime> get _rangeDays {
    final range = _customRange;
    if (range == null) {
      return const <DateTime>[];
    }
    final dayCount = range.end.difference(range.start).inDays + 1;
    return List.generate(dayCount, (i) => range.start.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = _clampToWeek(DateTime.now());
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  void _jumpToDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final newWeekStart = mondayOfWeek(normalized);
    if (newWeekStart != widget.weekStart) {
      widget.onWeekStartChanged(newWeekStart);
    }
    setState(() {
      _focusedDay = normalized;
      _viewMode = _CalendarViewMode.day;
    });
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        _customRange ??
        DateTimeRange(start: today, end: today.add(const Duration(days: 4)));
    final picked = await showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _customRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
      _viewMode = _CalendarViewMode.range;
    });
  }

  void _shiftCustomRange(int directionInRangeLengths) {
    final range = _customRange;
    if (range == null) {
      return;
    }
    final length = range.end.difference(range.start).inDays + 1;
    final offset = Duration(days: directionInRangeLengths * length);
    setState(() {
      _customRange = DateTimeRange(
        start: range.start.add(offset),
        end: range.end.add(offset),
      );
    });
  }

  @override
  void dispose() {
    _hourGridScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TaskCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _focusedDay = _clampToWeek(_focusedDay);
    }
  }

  DateTime _clampToWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final days = _days;
    if (days.any((d) => d == normalized)) {
      return normalized;
    }
    return widget.weekStart;
  }

  List<_CalendarBlock> _blocksForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final blocks = <_CalendarBlock>[];
    for (final task in widget.tasks) {
      final due = task.dueAt;
      final start = task.startAt;
      final anchor = due ?? start;
      if (anchor == null) {
        continue;
      }
      final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
      if (anchorDay != dayStart) {
        continue;
      }
      DateTime blockStart;
      DateTime blockEnd;
      final sameDayRange =
          start != null &&
          due != null &&
          DateTime(start.year, start.month, start.day) == anchorDay;
      if (sameDayRange && due.isAfter(start)) {
        blockStart = start;
        blockEnd = due;
      } else {
        blockStart = anchor;
        blockEnd = anchor.add(const Duration(minutes: 45));
      }
      blocks.add(_CalendarBlock(task: task, start: blockStart, end: blockEnd));
    }
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks;
  }

  bool _hasAnyBlockIn(List<DateTime> days) =>
      days.any((day) => _blocksForDay(day).isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final days = _days;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _kCalendarCompactBreakpoint;
        final scale = TaskDensityScope.of(context);
        final viewMode =
            _viewMode ??
            (isCompact ? _CalendarViewMode.day : _CalendarViewMode.week);
        final rangeDays = _rangeDays;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CalendarViewModeSelector(
                  selected: viewMode == _CalendarViewMode.range
                      ? null
                      : viewMode,
                  onChanged: (mode) => setState(() => _viewMode = mode),
                ),
                _CalendarCustomRangePill(
                  range: _customRange,
                  onTap: () => unawaited(_pickCustomRange(context)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (viewMode == _CalendarViewMode.month)
              _CalendarMonthNavHeader(
                month: _focusedMonth,
                onPrevMonth: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                    1,
                  );
                }),
                onNextMonth: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                    1,
                  );
                }),
                onToday: () {
                  final today = DateTime.now();
                  setState(() {
                    _focusedMonth = DateTime(today.year, today.month, 1);
                  });
                },
              )
            else if (viewMode == _CalendarViewMode.range && _customRange != null)
              _CalendarRangeNavHeader(
                range: _customRange!,
                onPrevRange: () => _shiftCustomRange(-1),
                onNextRange: () => _shiftCustomRange(1),
                onPickRange: () => unawaited(_pickCustomRange(context)),
              )
            else
              _CalendarNavHeader(
                weekStart: widget.weekStart,
                onPrevWeek: () => widget.onWeekStartChanged(
                  widget.weekStart.subtract(const Duration(days: 7)),
                ),
                onNextWeek: () => widget.onWeekStartChanged(
                  widget.weekStart.add(const Duration(days: 7)),
                ),
                onToday: () {
                  final today = DateTime.now();
                  widget.onWeekStartChanged(
                    today.subtract(Duration(days: today.weekday - 1)),
                  );
                  setState(() {
                    _focusedDay = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );
                  });
                },
              ),
            const SizedBox(height: 10),
            if (viewMode == _CalendarViewMode.day) ...[
              _CalendarDayStrip(
                days: days,
                focusedDay: _focusedDay,
                onDaySelected: (day) => setState(() => _focusedDay = day),
              ),
              const SizedBox(height: 10),
            ],
            if (viewMode == _CalendarViewMode.month)
              Expanded(
                child: _CalendarMonthGrid(
                  month: _focusedMonth,
                  tasks: widget.tasks,
                  onDaySelected: _jumpToDay,
                ),
              )
            else if (viewMode == _CalendarViewMode.range && rangeDays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _pickPeriodHint(context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else if (!_hasAnyBlockIn(
              viewMode == _CalendarViewMode.range ? rangeDays : days,
            ))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.taskTimelineEmptyState,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  controller: _hourGridScrollController,
                  child: viewMode == _CalendarViewMode.day
                      ? _CalendarGrid(
                          days: [_focusedDay],
                          blocksForDay: _blocksForDay,
                          selectedTaskId: widget.selectedTaskId,
                          onTaskTap: widget.onTaskTap,
                          showDayHeaders: false,
                          assigneeAvatarUrlByUserId:
                              widget.assigneeAvatarUrlByUserId,
                        )
                      : viewMode == _CalendarViewMode.range
                      ? _HorizontalScrollIfNarrow(
                          minWidth: rangeDays.length * 96.0 * scale,
                          child: _CalendarGrid(
                            days: rangeDays,
                            blocksForDay: _blocksForDay,
                            selectedTaskId: widget.selectedTaskId,
                            onTaskTap: widget.onTaskTap,
                            showDayHeaders: true,
                            assigneeAvatarUrlByUserId:
                                widget.assigneeAvatarUrlByUserId,
                          ),
                        )
                      : _CalendarGrid(
                          days: days,
                          blocksForDay: _blocksForDay,
                          selectedTaskId: widget.selectedTaskId,
                          onTaskTap: widget.onTaskTap,
                          showDayHeaders: true,
                          assigneeAvatarUrlByUserId:
                              widget.assigneeAvatarUrlByUserId,
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Lets [child] size itself normally on wide layouts; on narrow ones it
/// enforces [minWidth] and scrolls horizontally instead of squeezing an
/// arbitrary-length custom range unreadably.
class _HorizontalScrollIfNarrow extends StatelessWidget {
  const _HorizontalScrollIfNarrow({required this.minWidth, required this.child});

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return child;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: child),
        );
      },
    );
  }
}

class _CalendarViewModeSelector extends StatelessWidget {
  const _CalendarViewModeSelector({
    required this.selected,
    required this.onChanged,
  });

  /// `null` when a custom range (outside Day/Week/Month) is active — none of
  /// the three segments is highlighted in that case.
  final _CalendarViewMode? selected;
  final ValueChanged<_CalendarViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SegmentedButton<_CalendarViewMode>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelSmall,
      ),
      emptySelectionAllowed: true,
      segments: [
        ButtonSegment(
          value: _CalendarViewMode.day,
          label: Text(_dayViewLabel(context)),
        ),
        ButtonSegment(
          value: _CalendarViewMode.week,
          label: Text(_weekViewLabel(context)),
        ),
        ButtonSegment(
          value: _CalendarViewMode.month,
          label: Text(_monthViewLabel(context)),
        ),
      ],
      selected: selected == null ? const {} : {selected!},
      onSelectionChanged: (next) {
        // With emptySelectionAllowed (needed to show none of the three
        // segments highlighted while a custom range is active), tapping the
        // already-selected segment toggles it off instead of a no-op — just
        // ignore that rather than reading .first off an empty set.
        if (next.isNotEmpty) {
          onChanged(next.first);
        }
      },
    );
  }
}

String _formatRangeLabel(DateTimeRange range, String locale) {
  final sameMonth =
      range.start.month == range.end.month &&
      range.start.year == range.end.year;
  return sameMonth
      ? '${DateFormat.d(locale).format(range.start)}–${DateFormat.yMMMd(locale).format(range.end)}'
      : '${DateFormat.MMMd(locale).format(range.start)} – ${DateFormat.yMMMd(locale).format(range.end)}';
}

/// Rounded outline pill showing the currently picked custom period (or an
/// invitation to pick one) — tapping it opens [showDateRangePicker].
class _CalendarCustomRangePill extends StatelessWidget {
  const _CalendarCustomRangePill({required this.range, required this.onTap});

  final DateTimeRange? range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final label = range == null
        ? _customPeriodLabel(context)
        : _formatRangeLabel(range!, locale);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nav header for a custom picked range: prev/next shift the whole window
/// by its own length, and the trailing button reopens the date-range picker.
class _CalendarRangeNavHeader extends StatelessWidget {
  const _CalendarRangeNavHeader({
    required this.range,
    required this.onPrevRange,
    required this.onNextRange,
    required this.onPickRange,
  });

  final DateTimeRange range;
  final VoidCallback onPrevRange;
  final VoidCallback onNextRange;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = _formatRangeLabel(range, locale);

    return Row(
      children: [
        IconButton(
          onPressed: onPrevRange,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: onNextRange,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onPickRange,
          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
          label: Text(_editPeriodLabel(context)),
        ),
      ],
    );
  }
}

class _CalendarMonthNavHeader extends StatelessWidget {
  const _CalendarMonthNavHeader({
    required this.month,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat.yMMMM(locale).format(month);

    return Row(
      children: [
        IconButton(
          onPressed: onPrevMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: onNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onToday, child: Text(l10n.today)),
      ],
    );
  }
}

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.month,
    required this.tasks,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<TaskEntity> tasks;
  final ValueChanged<DateTime> onDaySelected;

  static const _maxChipsPerDay = 2;
  // Fixed per-row height + inner scroll, rather than dividing whatever
  // vertical space happens to be available across 6 rows: on short mobile
  // screens that division could leave a row shorter than a day-cell's own
  // content (day number + chips), overflowing it.
  static const _rowHeight = 92.0;

  List<DateTime> _gridDays() {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  List<TaskEntity> _tasksForDay(DateTime day) {
    return tasks.where((task) {
      final anchor = task.dueAt ?? task.startAt;
      if (anchor == null) {
        return false;
      }
      return anchor.year == day.year &&
          anchor.month == day.month &&
          anchor.day == day.day;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final days = _gridDays();
    final scale = TaskDensityScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6 * scale),
                child: Text(
                  DateFormat.E(locale).format(days[i]).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.descriptionColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(6, (weekIndex) {
                return SizedBox(
                  height: _rowHeight * scale,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (dayIndex) {
                      final day = days[weekIndex * 7 + dayIndex];
                      return Expanded(
                        child: _CalendarMonthCell(
                          day: day,
                          isCurrentMonth: day.month == month.month,
                          isToday: day == todayDate,
                          tasks: _tasksForDay(day),
                          maxChips: _maxChipsPerDay,
                          onTap: () => onDaySelected(day),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarMonthCell extends StatelessWidget {
  const _CalendarMonthCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.tasks,
    required this.maxChips,
    required this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final List<TaskEntity> tasks;
  final int maxChips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final borderColor = (colorScheme.borderColor ?? colorScheme.outlineVariant)
        .withValues(alpha: 0.25);
    final visibleTasks = tasks.take(maxChips).toList(growable: false);
    final overflowCount = tasks.length - visibleTasks.length;
    final scale = TaskDensityScope.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(border: Border.all(color: borderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 22 * scale,
                height: 22 * scale,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(color: accent, shape: BoxShape.circle)
                    : null,
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? (colorScheme.textInvertedColor ?? Colors.white)
                        : (isCurrentMonth
                              ? colorScheme.textColor
                              : colorScheme.descriptionColor),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2 * scale),
            for (final task in visibleTasks)
              Padding(
                padding: EdgeInsets.only(bottom: 2 * scale),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: taskStatusColor(
                      task.status,
                      colorScheme,
                    ).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3 * scale,
                      vertical: 1 * scale,
                    ),
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: taskStatusColor(task.status, colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (overflowCount > 0)
              Text(
                _moreTasksLabel(context, overflowCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _localizedCalendarText(
  BuildContext context, {
  required String it,
  required String en,
  String? fr,
  String? es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'it':
      return it;
    case 'fr':
      return fr ?? en;
    case 'es':
      return es ?? en;
    default:
      return en;
  }
}

String _dayViewLabel(BuildContext context) => _localizedCalendarText(
  context,
  it: 'Giorno',
  en: 'Day',
  fr: 'Jour',
  es: 'Dia',
);

String _weekViewLabel(BuildContext context) => _localizedCalendarText(
  context,
  it: 'Settimana',
  en: 'Week',
  fr: 'Semaine',
  es: 'Semana',
);

String _monthViewLabel(BuildContext context) => _localizedCalendarText(
  context,
  it: 'Mese',
  en: 'Month',
  fr: 'Mois',
  es: 'Mes',
);

String _moreTasksLabel(BuildContext context, int count) =>
    _localizedCalendarText(
      context,
      it: '+$count altri',
      en: '+$count more',
      fr: '+$count autres',
      es: '+$count mas',
    );

String _customPeriodLabel(BuildContext context) => _localizedCalendarText(
  context,
  it: 'Periodo',
  en: 'Period',
  fr: 'Periode',
  es: 'Periodo',
);

String _pickPeriodHint(BuildContext context) => _localizedCalendarText(
  context,
  it: 'Scegli un periodo da visualizzare.',
  en: 'Choose a period to view.',
  fr: 'Choisissez une periode a afficher.',
  es: 'Elige un periodo para ver.',
);

String _editPeriodLabel(BuildContext context) => _localizedCalendarText(
  context,
  it: 'Modifica',
  en: 'Edit',
  fr: 'Modifier',
  es: 'Editar',
);

class _CalendarBlock {
  const _CalendarBlock({required this.task, required this.start, required this.end});

  final TaskEntity task;
  final DateTime start;
  final DateTime end;
}

class _CalendarNavHeader extends StatelessWidget {
  const _CalendarNavHeader({
    required this.weekStart,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onToday,
  });

  final DateTime weekStart;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final sameMonth =
        weekStart.month == weekEnd.month && weekStart.year == weekEnd.year;
    final rangeLabel = sameMonth
        ? '${DateFormat.d(locale).format(weekStart)}–${DateFormat.yMMMd(locale).format(weekEnd)}'
        : '${DateFormat.MMMd(locale).format(weekStart)}–${DateFormat.yMMMd(locale).format(weekEnd)}';

    return Row(
      children: [
        IconButton(
          onPressed: onPrevWeek,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            rangeLabel,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: onNextWeek,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onToday, child: Text(l10n.today)),
      ],
    );
  }
}

class _CalendarDayStrip extends StatelessWidget {
  const _CalendarDayStrip({
    required this.days,
    required this.focusedDay,
    required this.onDaySelected,
  });

  final List<DateTime> days;
  final DateTime focusedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final scale = TaskDensityScope.of(context);

    return SizedBox(
      height: 64 * scale,
      child: Row(
        children: days.map((day) {
          final isFocused = day == focusedDay;
          final isToday = day == todayDate;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3 * scale),
              child: InkWell(
                onTap: () => onDaySelected(day),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isFocused ? accent : colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFocused
                          ? accent
                          : (colorScheme.borderColor ??
                                colorScheme.outlineVariant),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E(locale).format(day).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isFocused
                              ? (colorScheme.textInvertedColor ?? Colors.white)
                              : colorScheme.descriptionColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isFocused
                              ? (colorScheme.textInvertedColor ?? Colors.white)
                              : (isToday ? accent : colorScheme.textColor),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.blocksForDay,
    required this.selectedTaskId,
    required this.onTaskTap,
    required this.showDayHeaders,
    this.assigneeAvatarUrlByUserId = const <String, String>{},
  });

  final List<DateTime> days;
  final List<_CalendarBlock> Function(DateTime day) blocksForDay;
  final String? selectedTaskId;
  final ValueChanged<TaskEntity> onTaskTap;
  final bool showDayHeaders;
  final Map<String, String> assigneeAvatarUrlByUserId;

  static const _hourCount = _kCalendarEndHour - _kCalendarStartHour;
  static const _gutterWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final scale = TaskDensityScope.of(context);
    final pixelsPerHour = _kPixelsPerHour * scale;
    final gutterWidth = _gutterWidth * scale;
    final columnDividerColor =
        (colorScheme.borderColor ?? colorScheme.outlineVariant)
            .withValues(alpha: 0.35);
    final columnDivider = BoxDecoration(
      border: Border(left: BorderSide(color: columnDividerColor)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDayHeaders)
          Row(
            children: [
              SizedBox(width: gutterWidth),
              Expanded(child: _CalendarWeekdayPillRow(days: days)),
            ],
          ),
        SizedBox(
          height: _hourCount * pixelsPerHour,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: gutterWidth,
                child: Column(
                  children: List.generate(_hourCount, (i) {
                    final hour = _kCalendarStartHour + i;
                    return SizedBox(
                      height: pixelsPerHour,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          DateFormat.j(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(DateTime(2000, 1, 1, hour)),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              ...days.map(
                (day) => Expanded(
                  child: DecoratedBox(
                    decoration: columnDivider,
                    child: _CalendarDayColumn(
                      blocks: blocksForDay(day),
                      selectedTaskId: selectedTaskId,
                      onTaskTap: onTaskTap,
                      pixelsPerHour: pixelsPerHour,
                      assigneeAvatarUrlByUserId: assigneeAvatarUrlByUserId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single joined pill spanning the whole week/period, split into one segment
/// per day (full weekday name + day number) by thin dividers — matches the
/// reference "Monday, 12" header style requested for the grid views.
class _CalendarWeekdayPillRow extends StatelessWidget {
  const _CalendarWeekdayPillRow({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final scale = TaskDensityScope.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dividerColor = (colorScheme.borderColor ?? colorScheme.outlineVariant)
        .withValues(alpha: 0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.bgNavbarSurface ?? colorScheme.surfaceContainerHighest,
          border: Border.all(color: dividerColor),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < days.length; i++) ...[
                if (i > 0) Container(width: 1, color: dividerColor),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10 * scale,
                      horizontal: 6 * scale,
                    ),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                          children: [
                            TextSpan(
                              text: DateFormat.EEEE(locale).format(days[i]),
                            ),
                            const TextSpan(text: ', '),
                            TextSpan(
                              text: '${days[i].day}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textColor,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDayColumn extends StatelessWidget {
  const _CalendarDayColumn({
    required this.blocks,
    required this.selectedTaskId,
    required this.onTaskTap,
    required this.pixelsPerHour,
    this.assigneeAvatarUrlByUserId = const <String, String>{},
  });

  final List<_CalendarBlock> blocks;
  final String? selectedTaskId;
  final ValueChanged<TaskEntity> onTaskTap;
  final double pixelsPerHour;
  final Map<String, String> assigneeAvatarUrlByUserId;

  double _topForTime(DateTime time) {
    final minutes = (time.hour * 60 + time.minute).clamp(
      _kCalendarStartHour * 60,
      _kCalendarEndHour * 60,
    );
    return (minutes - _kCalendarStartHour * 60) / 60.0 * pixelsPerHour;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gridLineColor = (colorScheme.borderColor ?? colorScheme.outlineVariant)
        .withValues(alpha: 0.3);
    final scale = TaskDensityScope.of(context);
    const hourCount = _kCalendarEndHour - _kCalendarStartHour;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2 * scale),
      child: Stack(
        children: [
          Column(
            children: List.generate(
              hourCount,
              (_) => Container(
                height: pixelsPerHour,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: gridLineColor)),
                ),
              ),
            ),
          ),
          for (final block in blocks)
            Positioned(
              top: _topForTime(block.start) + 1,
              left: 0,
              right: 0,
              height: (_topForTime(block.end) - _topForTime(block.start)).clamp(
                28.0 * scale,
                double.infinity,
              ),
              child: _CalendarEventCard(
                block: block,
                selected: block.task.id == selectedTaskId,
                onTap: () => onTaskTap(block.task),
                assigneeAvatarUrl:
                    assigneeAvatarUrlByUserId[block.task.assigneeUserId
                        ?.trim()],
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.block,
    required this.selected,
    required this.onTap,
    this.assigneeAvatarUrl,
  });

  final _CalendarBlock block;
  final bool selected;
  final VoidCallback onTap;
  final String? assigneeAvatarUrl;

  String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    return parts.map((part) => part[0].toUpperCase()).take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final statusColor = taskStatusColor(block.task.status, colorScheme);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeRangeLabel =
        '${DateFormat.jm(locale).format(block.start)} - ${DateFormat.jm(locale).format(block.end)}';
    final assignee = block.task.assigneeDisplayName?.trim();
    final scale = TaskDensityScope.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: statusColor, width: 2)
                : Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showTimeRange = constraints.maxHeight >= 42 * scale;
              final showAvatar =
                  assignee?.isNotEmpty == true &&
                  constraints.maxHeight >= 58 * scale;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      block.task.title,
                      maxLines: showTimeRange ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showTimeRange) ...[
                      SizedBox(height: 2 * scale),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11 * scale,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 3 * scale),
                          Flexible(
                            child: Text(
                              timeRangeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (showAvatar) ...[
                      SizedBox(height: 4 * scale),
                      AvatarApp(
                        imageUrl: assigneeAvatarUrl,
                        initials: _initialsFor(assignee!),
                        size: 18 * scale,
                        backgroundColor: colorScheme.avatarBg ?? Colors.grey,
                        textColor: colorScheme.avatarTextColor ?? Colors.white,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
