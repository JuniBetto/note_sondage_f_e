import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

const _kCalendarStartHour = 7;
const _kCalendarEndHour = 20;
const _kPixelsPerHour = 64.0;
const _kCalendarCompactBreakpoint = 760.0;

enum _CalendarViewMode { day, week, month }

DateTime mondayOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

/// Time-of-day calendar with an explicit Day / Week / Month switcher —
/// Day and Week render the hour-grid agenda (single day or full week);
/// Month renders a classic month grid with per-day event chips. Ported from
/// [TaskCalendarView]'s styling/interaction pattern, trimmed to the three
/// granularities Event needs (no custom-range mode).
class EventCalendarView extends StatefulWidget {
  const EventCalendarView({
    super.key,
    required this.events,
    required this.weekStart,
    required this.onWeekStartChanged,
    required this.onEventTap,
    required this.emptyStateTitle,
    required this.emptyStateSubtitle,
  });

  final List<EventEntity> events;
  final DateTime weekStart;
  final ValueChanged<DateTime> onWeekStartChanged;
  final ValueChanged<EventEntity> onEventTap;
  final String emptyStateTitle;
  final String emptyStateSubtitle;

  @override
  State<EventCalendarView> createState() => _EventCalendarViewState();
}

class _EventCalendarViewState extends State<EventCalendarView> {
  late DateTime _focusedDay;
  late DateTime _focusedMonth;
  // null until the user explicitly picks a mode: the initial mode still
  // follows screen width (day on narrow, week on wide), but from then on
  // it's fully under the user's control via the Day/Week/Month selector.
  _CalendarViewMode? _viewMode;

  List<DateTime> get _days =>
      List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));

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

  @override
  void didUpdateWidget(covariant EventCalendarView oldWidget) {
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
    for (final event in widget.events) {
      final anchorDay = DateTime(
        event.startsAt.year,
        event.startsAt.month,
        event.startsAt.day,
      );
      if (anchorDay != dayStart) {
        continue;
      }
      final blockStart = event.startsAt;
      final endsAt = event.endsAt;
      final blockEnd = endsAt != null && endsAt.isAfter(blockStart)
          ? endsAt
          : blockStart.add(const Duration(minutes: 45));
      blocks.add(_CalendarBlock(event: event, start: blockStart, end: blockEnd));
    }
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks;
  }

  bool _hasAnyBlockIn(List<DateTime> days) =>
      days.any((day) => _blocksForDay(day).isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _days;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _kCalendarCompactBreakpoint;
        final viewMode =
            _viewMode ??
            (isCompact ? _CalendarViewMode.day : _CalendarViewMode.week);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarViewModeSelector(
              selected: viewMode,
              onChanged: (mode) => setState(() => _viewMode = mode),
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
                  events: widget.events,
                  onDaySelected: _jumpToDay,
                ),
              )
            else if (!_hasAnyBlockIn(
              viewMode == _CalendarViewMode.day ? [_focusedDay] : days,
            ))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        widget.emptyStateTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.emptyStateSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: viewMode == _CalendarViewMode.day
                      ? _CalendarGrid(
                          days: [_focusedDay],
                          blocksForDay: _blocksForDay,
                          onEventTap: widget.onEventTap,
                          showDayHeaders: false,
                        )
                      : _CalendarGrid(
                          days: days,
                          blocksForDay: _blocksForDay,
                          onEventTap: widget.onEventTap,
                          showDayHeaders: true,
                        ),
                ),
              ),
          ],
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

  final _CalendarViewMode selected;
  final ValueChanged<_CalendarViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_CalendarViewMode>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelSmall,
      ),
      segments: [
        ButtonSegment(
          value: _CalendarViewMode.day,
          label: Text(l10n.eventCalendarDayLabel),
        ),
        ButtonSegment(
          value: _CalendarViewMode.week,
          label: Text(l10n.eventCalendarWeekLabel),
        ),
        ButtonSegment(
          value: _CalendarViewMode.month,
          label: Text(l10n.eventCalendarMonthLabel),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (next) {
        if (next.isNotEmpty) {
          onChanged(next.first);
        }
      },
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

    return SizedBox(
      height: 64,
      child: Row(
        children: days.map((day) {
          final isFocused = day == focusedDay;
          final isToday = day == todayDate;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
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

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.month,
    required this.events,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<EventEntity> events;
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

  List<EventEntity> _eventsForDay(DateTime day) {
    return events.where((event) {
      final anchor = event.startsAt;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                  height: _rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (dayIndex) {
                      final day = days[weekIndex * 7 + dayIndex];
                      return Expanded(
                        child: _CalendarMonthCell(
                          day: day,
                          isCurrentMonth: day.month == month.month,
                          isToday: day == todayDate,
                          events: _eventsForDay(day),
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
    required this.events,
    required this.maxChips,
    required this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final List<EventEntity> events;
  final int maxChips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final borderColor = (colorScheme.borderColor ?? colorScheme.outlineVariant)
        .withValues(alpha: 0.25);
    final visibleEvents = events.take(maxChips).toList(growable: false);
    final overflowCount = events.length - visibleEvents.length;

    return InkWell(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: borderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 22,
                height: 22,
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
            const SizedBox(height: 2),
            for (final event in visibleEvents)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (overflowCount > 0)
              Text(
                l10n.eventCalendarMoreLabel(overflowCount),
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

class _CalendarBlock {
  const _CalendarBlock({
    required this.event,
    required this.start,
    required this.end,
  });

  final EventEntity event;
  final DateTime start;
  final DateTime end;
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.blocksForDay,
    required this.onEventTap,
    required this.showDayHeaders,
  });

  final List<DateTime> days;
  final List<_CalendarBlock> Function(DateTime day) blocksForDay;
  final ValueChanged<EventEntity> onEventTap;
  final bool showDayHeaders;

  static const _hourCount = _kCalendarEndHour - _kCalendarStartHour;
  static const _gutterWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
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
              const SizedBox(width: _gutterWidth),
              Expanded(child: _CalendarWeekdayPillRow(days: days)),
            ],
          ),
        SizedBox(
          height: _hourCount * _kPixelsPerHour,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _gutterWidth,
                child: Column(
                  children: List.generate(_hourCount, (i) {
                    final hour = _kCalendarStartHour + i;
                    return SizedBox(
                      height: _kPixelsPerHour,
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
                      onEventTap: onEventTap,
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

/// Single joined pill spanning the whole week, split into one segment per
/// day (full weekday name + day number) by thin dividers.
class _CalendarWeekdayPillRow extends StatelessWidget {
  const _CalendarWeekdayPillRow({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 6,
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
  const _CalendarDayColumn({required this.blocks, required this.onEventTap});

  final List<_CalendarBlock> blocks;
  final ValueChanged<EventEntity> onEventTap;

  double _topForTime(DateTime time) {
    final minutes = (time.hour * 60 + time.minute).clamp(
      _kCalendarStartHour * 60,
      _kCalendarEndHour * 60,
    );
    return (minutes - _kCalendarStartHour * 60) / 60.0 * _kPixelsPerHour;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gridLineColor = (colorScheme.borderColor ?? colorScheme.outlineVariant)
        .withValues(alpha: 0.3);
    const hourCount = _kCalendarEndHour - _kCalendarStartHour;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        children: [
          Column(
            children: List.generate(
              hourCount,
              (_) => Container(
                height: _kPixelsPerHour,
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
                28.0,
                double.infinity,
              ),
              child: _CalendarEventCard(
                block: block,
                onTap: () => onEventTap(block.event),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.block, required this.onTap});

  final _CalendarBlock block;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeRangeLabel =
        '${DateFormat.jm(locale).format(block.start)} - ${DateFormat.jm(locale).format(block.end)}';
    final location = block.event.location?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showTimeRange = constraints.maxHeight >= 42;
              final showLocation =
                  location?.isNotEmpty == true &&
                  constraints.maxHeight >= 58;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      block.event.title,
                      maxLines: showTimeRange ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showTimeRange) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
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
                    if (showLocation) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              location!,
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
