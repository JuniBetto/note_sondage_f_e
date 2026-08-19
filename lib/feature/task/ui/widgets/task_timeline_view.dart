import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/ui/task_density_scope.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';
import 'package:note_sondage/ui/widgets/custom_date_range_picker.dart';

const _kTimelineRowHeight = 104.0;

/// Cards are anchored to their start day but never shrink below this width,
/// so short (even single-day) tasks stay readable — they may overlap later
/// days' grid columns, same as a real Gantt chart.
const _kTimelineCardMinWidth = 240.0;

/// Minimum width per day column — used to size the horizontally-scrollable
/// area for Month/Range windows with many days.
const _kTimelineMinDayColumnWidth = 96.0;

const _kTimelineCompactBreakpoint = 760.0;

enum _TimelineViewMode { day, week, month, range }

/// Normalizes [date] to midnight on the Monday of its week.
DateTime mondayOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

/// Gantt view with an explicit Day / Week / Month switcher (plus a custom
/// period picker) — mirrors [TaskCalendarView]'s view-mode architecture.
/// Tasks are rendered as bars spanning `startAt` to `dueAt` (or as a
/// single-day marker when only one of the two is set); tasks without either
/// date can't be positioned and are excluded.
class TaskTimelineView extends StatefulWidget {
  const TaskTimelineView({
    super.key,
    required this.tasks,
    required this.weekStart,
    required this.onWeekStartChanged,
    required this.selectedTaskId,
    required this.onTaskTap,
  });

  final List<TaskEntity> tasks;
  final DateTime weekStart;
  final ValueChanged<DateTime> onWeekStartChanged;
  final String? selectedTaskId;
  final ValueChanged<TaskEntity> onTaskTap;

  @override
  State<TaskTimelineView> createState() => _TaskTimelineViewState();
}

class _TaskTimelineViewState extends State<TaskTimelineView> {
  late DateTime _focusedDay;
  late DateTime _focusedMonth;
  // null until the user explicitly picks a mode: the initial mode still
  // follows screen width (day on narrow, week on wide), but from then on
  // it's fully under the user's control via the Day/Week/Month selector.
  _TimelineViewMode? _viewMode;
  DateTimeRange? _customRange;

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));

  List<DateTime> get _monthDays {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    return List.generate(
      daysInMonth,
      (i) => DateTime(_focusedMonth.year, _focusedMonth.month, i + 1),
    );
  }

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

  @override
  void didUpdateWidget(covariant TaskTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _focusedDay = _clampToWeek(_focusedDay);
    }
  }

  DateTime _clampToWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final days = _weekDays;
    if (days.any((d) => d == normalized)) {
      return normalized;
    }
    return widget.weekStart;
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
      _viewMode = _TimelineViewMode.range;
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

  List<_TimelineRow> _buildRows(List<DateTime> days) {
    if (days.isEmpty) {
      return const <_TimelineRow>[];
    }
    final windowStart = days.first;
    final windowEnd = days.last;
    final rows = <_TimelineRow>[];
    for (final task in widget.tasks) {
      final effectiveStart = task.startAt ?? task.dueAt;
      final effectiveEnd = task.dueAt ?? task.startAt;
      if (effectiveStart == null || effectiveEnd == null) {
        continue;
      }
      var startDate = DateTime(
        effectiveStart.year,
        effectiveStart.month,
        effectiveStart.day,
      );
      var endDate = DateTime(
        effectiveEnd.year,
        effectiveEnd.month,
        effectiveEnd.day,
      );
      if (endDate.isBefore(startDate)) {
        final swap = startDate;
        startDate = endDate;
        endDate = swap;
      }
      if (startDate.isAfter(windowEnd) || endDate.isBefore(windowStart)) {
        continue;
      }
      final clippedStart = startDate.isBefore(windowStart)
          ? windowStart
          : startDate;
      final clippedEnd = endDate.isAfter(windowEnd) ? windowEnd : endDate;
      rows.add(
        _TimelineRow(
          task: task,
          startIndex: clippedStart.difference(windowStart).inDays,
          endIndex: clippedEnd.difference(windowStart).inDays,
          sortKey: effectiveStart,
        ),
      );
    }
    rows.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _kTimelineCompactBreakpoint;
        final scale = TaskDensityScope.of(context);
        final viewMode =
            _viewMode ??
            (isCompact ? _TimelineViewMode.day : _TimelineViewMode.week);
        final days = switch (viewMode) {
          _TimelineViewMode.day => [_focusedDay],
          _TimelineViewMode.week => _weekDays,
          _TimelineViewMode.month => _monthDays,
          _TimelineViewMode.range => _rangeDays,
        };
        final rows = _buildRows(days);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TimelineViewModeSelector(
                  selected: viewMode == _TimelineViewMode.range
                      ? null
                      : viewMode,
                  onChanged: (mode) => setState(() => _viewMode = mode),
                ),
                _TimelineCustomRangePill(
                  range: _customRange,
                  onTap: () => unawaited(_pickCustomRange(context)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (viewMode == _TimelineViewMode.month)
              _TimelineMonthNavHeader(
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
            else if (viewMode == _TimelineViewMode.range &&
                _customRange != null)
              _TimelineRangeNavHeader(
                range: _customRange!,
                onPrevRange: () => _shiftCustomRange(-1),
                onNextRange: () => _shiftCustomRange(1),
                onPickRange: () => unawaited(_pickCustomRange(context)),
              )
            else
              _TimelineNavHeader(
                weekStart: widget.weekStart,
                onPrevWeek: () => widget.onWeekStartChanged(
                  widget.weekStart.subtract(const Duration(days: 7)),
                ),
                onNextWeek: () => widget.onWeekStartChanged(
                  widget.weekStart.add(const Duration(days: 7)),
                ),
                onToday: () {
                  final today = DateTime.now();
                  widget.onWeekStartChanged(mondayOfWeek(today));
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
            if (viewMode == _TimelineViewMode.day) ...[
              _TimelineDayStrip(
                days: _weekDays,
                focusedDay: _focusedDay,
                onDaySelected: (day) => setState(() => _focusedDay = day),
              ),
              const SizedBox(height: 6),
            ],
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        l10n.taskTimelineEmptyState,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _HorizontalScrollIfNarrow(
                      minWidth:
                          days.length * _kTimelineMinDayColumnWidth * scale <
                              560 * scale
                          ? 560 * scale
                          : days.length * _kTimelineMinDayColumnWidth * scale,
                      child: _TimelineBody(
                        days: days,
                        rows: rows,
                        selectedTaskId: widget.selectedTaskId,
                        onTaskTap: widget.onTaskTap,
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
/// enforces [minWidth] and scrolls horizontally instead of squeezing
/// multi-column content unreadably.
class _HorizontalScrollIfNarrow extends StatelessWidget {
  const _HorizontalScrollIfNarrow({
    required this.minWidth,
    required this.child,
  });

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

/// Day header row + today-column wash + the scrollable list of task bars —
/// kept together so both share the exact same width basis (whatever
/// [_HorizontalScrollIfNarrow] gives this widget).
class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.days,
    required this.rows,
    required this.selectedTaskId,
    required this.onTaskTap,
  });

  final List<DateTime> days;
  final List<_TimelineRow> rows;
  final String? selectedTaskId;
  final ValueChanged<TaskEntity> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final scale = TaskDensityScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TimelineDayHeaderRow(days: days),
        SizedBox(height: 6 * scale),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _TimelineTodayColumn(days: days)),
              ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _TimelineTaskRow(
                    task: row.task,
                    dayCount: days.length,
                    startIndex: row.startIndex,
                    endIndex: row.endIndex,
                    selected: row.task.id == selectedTaskId,
                    onTap: () => onTaskTap(row.task),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRow {
  const _TimelineRow({
    required this.task,
    required this.startIndex,
    required this.endIndex,
    required this.sortKey,
  });

  final TaskEntity task;
  final int startIndex;
  final int endIndex;
  final DateTime sortKey;
}

class _TimelineViewModeSelector extends StatelessWidget {
  const _TimelineViewModeSelector({
    required this.selected,
    required this.onChanged,
  });

  /// `null` when a custom range (outside Day/Week/Month) is active — none of
  /// the three segments is highlighted in that case.
  final _TimelineViewMode? selected;
  final ValueChanged<_TimelineViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SegmentedButton<_TimelineViewMode>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelSmall,
      ),
      emptySelectionAllowed: true,
      segments: [
        ButtonSegment(
          value: _TimelineViewMode.day,
          label: Text(_dayViewLabel(context)),
        ),
        ButtonSegment(
          value: _TimelineViewMode.week,
          label: Text(_weekViewLabel(context)),
        ),
        ButtonSegment(
          value: _TimelineViewMode.month,
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

String _formatTimelineRangeLabel(DateTimeRange range, String locale) {
  final sameMonth =
      range.start.month == range.end.month &&
      range.start.year == range.end.year;
  return sameMonth
      ? '${DateFormat.d(locale).format(range.start)}–${DateFormat.yMMMd(locale).format(range.end)}'
      : '${DateFormat.MMMd(locale).format(range.start)} – ${DateFormat.yMMMd(locale).format(range.end)}';
}

/// Rounded outline pill showing the currently picked custom period (or an
/// invitation to pick one) — tapping it opens [showDateRangePicker].
class _TimelineCustomRangePill extends StatelessWidget {
  const _TimelineCustomRangePill({required this.range, required this.onTap});

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
        : _formatTimelineRangeLabel(range!, locale);

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
class _TimelineRangeNavHeader extends StatelessWidget {
  const _TimelineRangeNavHeader({
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
    final label = _formatTimelineRangeLabel(range, locale);

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

class _TimelineMonthNavHeader extends StatelessWidget {
  const _TimelineMonthNavHeader({
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

String _localizedTimelineText(
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

String _dayViewLabel(BuildContext context) => _localizedTimelineText(
  context,
  it: 'Giorno',
  en: 'Day',
  fr: 'Jour',
  es: 'Dia',
);

String _weekViewLabel(BuildContext context) => _localizedTimelineText(
  context,
  it: 'Settimana',
  en: 'Week',
  fr: 'Semaine',
  es: 'Semana',
);

String _monthViewLabel(BuildContext context) => _localizedTimelineText(
  context,
  it: 'Mese',
  en: 'Month',
  fr: 'Mois',
  es: 'Mes',
);

String _customPeriodLabel(BuildContext context) => _localizedTimelineText(
  context,
  it: 'Periodo',
  en: 'Period',
  fr: 'Periode',
  es: 'Periodo',
);

String _editPeriodLabel(BuildContext context) => _localizedTimelineText(
  context,
  it: 'Modifica',
  en: 'Edit',
  fr: 'Modifier',
  es: 'Editar',
);

class _TimelineNavHeader extends StatelessWidget {
  const _TimelineNavHeader({
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

class _TimelineDayStrip extends StatelessWidget {
  const _TimelineDayStrip({
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

/// Single joined pill spanning the whole week/month/period, split into one
/// segment per day (full weekday name + day number) by thin dividers —
/// matches the reference "Monday, 12" header style requested for the Gantt
/// column headers.
class _TimelineDayHeaderRow extends StatelessWidget {
  const _TimelineDayHeaderRow({required this.days});

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

class _TimelineTodayColumn extends StatelessWidget {
  const _TimelineTodayColumn({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayIndex = todayDate.difference(days.first).inDays;
    if (todayIndex < 0 || todayIndex >= days.length) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final accent = (colorScheme.primaryColor ?? colorScheme.primary)
        .withValues(alpha: 0.05);
    return Row(
      children: List.generate(
        days.length,
        (index) => Expanded(
          child: ColoredBox(
            color: index == todayIndex ? accent : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _TimelineTaskRow extends StatelessWidget {
  const _TimelineTaskRow({
    required this.task,
    required this.dayCount,
    required this.startIndex,
    required this.endIndex,
    required this.selected,
    required this.onTap,
  });

  final TaskEntity task;
  final int dayCount;
  final int startIndex;
  final int endIndex;
  final bool selected;
  final VoidCallback onTap;

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

  String _dateRangeLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = task.startAt;
    final due = task.dueAt;
    if (start != null && due != null) {
      final sameMonth =
          start.month == due.month && start.year == due.year;
      return sameMonth
          ? '${DateFormat.d(locale).format(start)}–${DateFormat.yMMMd(locale).format(due)}'
          : '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(due)}';
    }
    final only = due ?? start;
    return only == null ? '' : DateFormat.yMMMd(locale).format(only);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final statusColor = taskStatusColor(task.status, colorScheme);
    final priorityColor = taskPriorityColor(task.priority, colorScheme);
    final gridLineColor = (colorScheme.borderColor ?? colorScheme.outlineVariant)
        .withValues(alpha: 0.35);
    final assignee = task.assigneeDisplayName?.trim();
    final dateRangeLabel = _dateRangeLabel(context);
    final scale = TaskDensityScope.of(context);

    return SizedBox(
      height: _kTimelineRowHeight * scale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dayWidth = constraints.maxWidth / dayCount;
          final left = startIndex * dayWidth;
          final spanWidth = (endIndex - startIndex + 1) * dayWidth - 6 * scale;
          final width = spanWidth < _kTimelineCardMinWidth * scale
              ? _kTimelineCardMinWidth * scale
              : spanWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: List.generate(
                  dayCount,
                  (_) => Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: gridLineColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left + 3 * scale,
                width: width,
                top: 4 * scale,
                bottom: 4 * scale,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    padding: EdgeInsets.fromLTRB(
                      14 * scale,
                      12 * scale,
                      14 * scale,
                      10 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? statusColor
                            : statusColor.withValues(alpha: 0.22),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * scale,
                                vertical: 3 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                taskStatusLabel(task.status, context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (dateRangeLabel.isNotEmpty)
                          Text(
                            dateRangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scale,
                                  vertical: 3 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  taskPriorityLabel(task.priority, context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (assignee?.isNotEmpty == true) ...[
                              SizedBox(width: 8 * scale),
                              AvatarApp(
                                initials: _initialsFor(assignee!),
                                size: 22 * scale,
                                backgroundColor:
                                    colorScheme.avatarBg ?? Colors.grey,
                                textColor:
                                    colorScheme.avatarTextColor ?? Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
