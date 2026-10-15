import 'package:flutter/material.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_duration.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/// Messaggio informativo sotto gli orari di un turno che finisce il giorno
/// dopo: indica la durata e se il turno occupa uno o due giorni. In evidenza
/// quando supera le 24 ore. Non compare se il turno e' nello stesso giorno.
class ShiftOvernightNotice extends StatelessWidget {
  const ShiftOvernightNotice({
    super.key,
    required this.start,
    required this.end,
    required this.overnight,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final bool overnight;

  @override
  Widget build(BuildContext context) {
    final duration = shiftDurationFor(
      start: start,
      end: end,
      overnight: overnight,
    );
    final endsNextDay =
        overnight ||
        duration.inMinutes >
            ((end.hour * 60 + end.minute) - (start.hour * 60 + start.minute));
    if (!endsNextDay) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;
    final days = shiftDaysSpanned(start: start, end: end, overnight: overnight);
    final label = formatReportDuration(duration);
    final overOneDay = duration > const Duration(hours: 24);
    final message = overOneDay
        ? loc.shiftNoticeOver24Hours(label)
        : days == 1
        ? loc.shiftNoticeSingleDay(label)
        : loc.shiftNoticeTwoDays(label);

    final color = overOneDay ? Colors.orange.shade800 : Colors.blue.shade700;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            overOneDay ? Icons.warning_amber_rounded : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
