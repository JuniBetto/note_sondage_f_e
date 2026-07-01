import 'package:flutter/material.dart';

class TimeRangePicker extends StatelessWidget {
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  const TimeRangePicker({
    super.key,
    required this.date,
    required this.start,
    required this.end,
    required this.onDateChanged,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  Future<void> _pickDate(
    BuildContext context,
    DateTime initialDate,
    ValueChanged<DateTime> onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initialTime,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        //color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _ValueRow(
            label: 'Data scadenza',
            value: _safeFormatDate(context, date),
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickDate(context, date, onDateChanged),
          ),
          const Divider(),
          _TimeRow(
            label: 'Ora inizio',
            time: start,
            onTap: () => _pickTime(context, start, onStartChanged),
          ),
          const Divider(),
          _TimeRow(
            label: 'Ora fine',
            time: end,
            onTap: () => _pickTime(context, end, onEndChanged),
          ),
        ],
      ),
    );
  }
}

String _safeFormatTime(BuildContext context, TimeOfDay time) {
  final localizations = Localizations.maybeLocaleOf(context) == null
      ? null
      : MaterialLocalizations.of(context);
  if (localizations != null) {
    try {
      return localizations.formatTimeOfDay(
        time,
        alwaysUse24HourFormat:
            MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
      );
    } catch (_) {
      // Fall back to a manual format below.
    }
  }

  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _safeFormatDate(BuildContext context, DateTime value) {
  final localizations = Localizations.maybeLocaleOf(context) == null
      ? null
      : MaterialLocalizations.of(context);
  if (localizations != null) {
    try {
      return localizations.formatShortDate(value);
    } catch (_) {
      // Fall back to a manual format below.
    }
  }

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _ValueRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = _safeFormatTime(context, time);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
