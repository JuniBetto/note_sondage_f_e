import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class StatusClocking extends StatelessWidget {
  const StatusClocking({
    super.key,
    this.isCompact = false,
    this.selectedTeamId,
    this.selectedDate,
  });
  final bool isCompact;
  final String? selectedTeamId;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<ClockingBloc, ClockingState>(
      builder: (context, state) {
        final records = switch (state) {
          ClockingRecordsLoaded(:final myRecords) => myRecords,
          ClockingActionInProgress(:final myRecords) => myRecords,
          ClockingActionSuccess(:final myRecords) => myRecords,
          _ => const <ClockingRecordEntity>[],
        };
        final effectiveSelectedDate = _normalizeDate(
          selectedDate ?? DateTime.now(),
        );
        final recordsForSelectedDate =
            records
                .where(
                  (record) => _isSameDay(record.date, effectiveSelectedDate),
                )
                .toList()
              ..sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));

        ClockingRecordEntity? activeRecord;
        for (final record in recordsForSelectedDate) {
          if (record.isActive) {
            activeRecord = record;
            break;
          }
        }
        final latestRecord =
            activeRecord ??
            (recordsForSelectedDate.isNotEmpty
                ? recordsForSelectedDate.first
                : null);

        final items = [
          _StatusItem(
            icon: Icons.login_rounded,
            label: localization.clockedInAt,
            time: latestRecord != null
                ? latestRecord.clockInFormatted
                : '--:--',
            color: Colors.green,
          ),
          _StatusItem(
            icon: Icons.coffee_rounded,
            label: localization.startBreakAt,
            time: latestRecord != null
                ? _formatTime(
                    activeRecord?.currentBreakStartedAt ??
                        latestRecord.lastBreakStartedAt,
                  )
                : '--:--',
            color: Colors.orange,
          ),
          _StatusItem(
            icon: Icons.play_circle_outline,
            label: localization.endBreakAt,
            time: latestRecord != null
                ? _formatTime(latestRecord.lastBreakEndedAt)
                : '--:--',
            color: Colors.blue,
          ),
          _StatusItem(
            icon: Icons.logout_rounded,
            label: localization.clockedOutAt,
            time: latestRecord != null
                ? latestRecord.clockOutFormatted
                : '--:--',
            color: Colors.red,
          ),
        ];

        if (isCompact) {
          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += 2) {
            final left = items[i];
            final right = i + 1 < items.length ? items[i + 1] : null;
            rows.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatusTile(
                        item: left,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ),
                    if (right != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatusTile(
                          item: right,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return Column(mainAxisSize: MainAxisSize.min, children: rows);
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => _StatusTile(
                  item: item,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime _sortDate(ClockingRecordEntity record) {
    return record.clockOutTime ??
        record.currentBreakStartedAt ??
        record.clockInTime ??
        record.date;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _StatusItem {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
  });

  final _StatusItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              Text(
                item.time,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.iconLabel,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
