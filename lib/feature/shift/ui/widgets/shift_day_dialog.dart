import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Result of the day dialog.
class ShiftDayDialogResult {
  const ShiftDayDialogResult({
    this.profileId,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.alarmOffsets,
    this.note,
    this.deleted = false,
  });

  final String? profileId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final List<int> alarmOffsets;
  final String? note;
  final bool deleted;
}

/// Modal bottom-sheet / dialog for assigning or editing a shift on a single day.
Future<ShiftDayDialogResult?> showShiftDayDialog({
  required BuildContext context,
  required DateTime date,
  required List<ShiftProfileEntity> profiles,
  ShiftAssignmentEntity? existing,
}) {
  return showModalBottomSheet<ShiftDayDialogResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ShiftDaySheet(date: date, profiles: profiles, existing: existing),
  );
}

class _ShiftDaySheet extends StatefulWidget {
  const _ShiftDaySheet({
    required this.date,
    required this.profiles,
    this.existing,
  });

  final DateTime date;
  final List<ShiftProfileEntity> profiles;
  final ShiftAssignmentEntity? existing;

  @override
  State<_ShiftDaySheet> createState() => _ShiftDaySheetState();
}

class _ShiftDaySheetState extends State<_ShiftDaySheet> {
  ShiftProfileEntity? _selectedProfile;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _overnight;
  late List<int> _alarmOffsets;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final ex = widget.existing!;
      _selectedProfile = widget.profiles
          .where((p) => p.id == ex.profileId)
          .firstOrNull;
      _startTime = ex.startTime;
      _endTime = ex.endTime;
      _overnight = ex.overnight;
      _alarmOffsets = List.from(ex.alarmOffsets);
      _noteCtrl.text = ex.note ?? '';
    } else {
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = const TimeOfDay(hour: 16, minute: 0);
      _overnight = false;
      _alarmOffsets = [-30, -15];
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _applyProfile(ShiftProfileEntity p) {
    setState(() {
      _selectedProfile = p;
      _startTime = p.startTime;
      _endTime = p.endTime;
      _overnight = p.overnight;
      _alarmOffsets = List.from(p.alarmOffsets);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final dateLabel =
        '${widget.date.day}/${widget.date.month}/${widget.date.year}';

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title bar ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing != null
                        ? '${loc.editAction} – $dateLabel'
                        : '${loc.addShift} – $dateLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: loc.removeAction,
                    onPressed: () => Navigator.of(context).pop(
                      ShiftDayDialogResult(
                        startTime: _startTime,
                        endTime: _endTime,
                        overnight: _overnight,
                        alarmOffsets: _alarmOffsets,
                        deleted: true,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Profile selector ──────────────────────────────────────────
            Text(
              loc.shiftProfile,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.descriptionColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.profiles.map((p) {
                final selected = _selectedProfile?.id == p.id;
                return GestureDetector(
                  onTap: () => _applyProfile(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? p.displayColor.withValues(alpha: 0.2)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? p.displayColor
                            : colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.displayColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Time pickers ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: loc.shiftStart,
                    value: _startTime,
                    onChanged: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: loc.shiftEnd,
                    value: _endTime,
                    onChanged: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Overnight toggle ──────────────────────────────────────────
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.overnightShift, style: theme.textTheme.bodySmall),
              value: _overnight,
              onChanged: (v) => setState(() => _overnight = v),
            ),

            // ── Alarm offsets ─────────────────────────────────────────────
            Text(
              loc.alarms,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.descriptionColor,
              ),
            ),
            const SizedBox(height: 6),
            _AlarmOffsetEditor(
              offsets: _alarmOffsets,
              onChanged: (offsets) => setState(() => _alarmOffsets = offsets),
            ),
            const SizedBox(height: 12),

            // ── Note ──────────────────────────────────────────────────────
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: loc.note,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // ── Confirm button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  ShiftDayDialogResult(
                    profileId: _selectedProfile?.id,
                    startTime: _startTime,
                    endTime: _endTime,
                    overnight: _overnight,
                    alarmOffsets: _alarmOffsets,
                    note: _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(loc.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  value.format(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AlarmOffsetEditor extends StatelessWidget {
  const _AlarmOffsetEditor({required this.offsets, required this.onChanged});

  final List<int> offsets;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...offsets.map((offset) {
          final label = offset < 0 ? '${offset} min' : '+$offset min';
          return Chip(
            label: Text(label, style: const TextStyle(fontSize: 11)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              final updated = List<int>.from(offsets)..remove(offset);
              onChanged(updated);
            },
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 14),
          label: const Text('Add', style: TextStyle(fontSize: 11)),
          onPressed: () => _addOffset(context),
        ),
      ],
    );
  }

  void _addOffset(BuildContext context) async {
    final ctrl = TextEditingController(text: '-30');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aggiungi sveglia'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Minuti (negativi = prima)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null) Navigator.of(ctx).pop(v);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
    if (result != null && !offsets.contains(result)) {
      final updated = List<int>.from(offsets)
        ..add(result)
        ..sort();
      onChanged(updated);
    }
  }
}
