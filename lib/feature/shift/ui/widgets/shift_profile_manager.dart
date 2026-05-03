import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ShiftProfileManager extends StatefulWidget {
  final List<ShiftProfileEntity> profiles;
  final bool isOwner;
  const ShiftProfileManager({
    super.key,
    required this.profiles,
    this.isOwner = false,
  });

  @override
  State<ShiftProfileManager> createState() => _ShiftProfileManagerState();
}

class _ShiftProfileManagerState extends State<ShiftProfileManager> {
  void _showCreateDialog() {
    _showProfileFormDialog(context, existing: null);
  }

  void _showEditDialog(ShiftProfileEntity profile) {
    _showProfileFormDialog(context, existing: profile);
  }

  Future<void> _showProfileFormDialog(
    BuildContext context, {
    ShiftProfileEntity? existing,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final colorCtrl = TextEditingController(text: existing?.color ?? '#4A90D9');
    TimeOfDay startTime = existing != null
        ? TimeOfDay(
            hour: existing.startTime.hour,
            minute: existing.startTime.minute,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = existing != null
        ? TimeOfDay(
            hour: existing.endTime.hour,
            minute: existing.endTime.minute,
          )
        : const TimeOfDay(hour: 18, minute: 0);
    bool overnight = existing?.overnight ?? false;
    bool isPublic = existing?.isPublic ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            existing == null ? loc.createCustomProfile : loc.editShiftProfile,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: loc.shiftProfileName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(
                    labelText: loc.shiftColor,
                    border: const OutlineInputBorder(),
                    prefixIcon: _ColorPreview(hex: colorCtrl.text),
                  ),
                  onChanged: (_) => setS(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerTile(
                        label: loc.shiftStart,
                        time: startTime,
                        onPicked: (t) => setS(() => startTime = t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TimePickerTile(
                        label: loc.shiftEnd,
                        time: endTime,
                        onPicked: (t) => setS(() => endTime = t),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  value: overnight,
                  onChanged: (v) => setS(() => overnight = v),
                  title: Text(loc.overnightShift),
                  contentPadding: EdgeInsets.zero,
                ),
                // ── Visibility toggle (owner only) ────────────────────
                if (widget.isOwner)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isPublic
                          ? Colors.blue.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPublic
                            ? Colors.blue.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      value: isPublic,
                      onChanged: (v) => setS(() => isPublic = v),
                      secondary: Icon(
                        isPublic ? Icons.public : Icons.lock_outline,
                        size: 18,
                        color: isPublic ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        isPublic ? 'Pubblico' : 'Privato',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        isPublic
                            ? 'Visibile a tutti i membri del team'
                            : 'Visibile solo a te',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (existing == null) {
                  context.read<ShiftBloc>().add(
                    CreateShiftProfileEvent(
                      name: name,
                      color: colorCtrl.text.trim(),
                      startTime: startTime,
                      endTime: endTime,
                      overnight: overnight,
                      alarmOffsets: const [],
                      isPublic: isPublic,
                    ),
                  );
                } else {
                  context.read<ShiftBloc>().add(
                    UpdateShiftProfileEvent(
                      profileId: existing.id,
                      name: name,
                      color: colorCtrl.text.trim(),
                      startTime: startTime,
                      endTime: endTime,
                      overnight: overnight,
                      alarmOffsets: const [],
                      isPublic: isPublic,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ShiftProfileEntity profile) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteShiftProfileConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.removeAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      context.read<ShiftBloc>().add(DeleteShiftProfileEvent(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final systemProfiles = widget.profiles.where((p) => p.isSystem).toList();
    final customProfiles = widget.profiles.where((p) => !p.isSystem).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.shiftProfile,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...systemProfiles.map((p) => _ProfileTile(profile: p, isSystem: true)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.customProfile,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              IconButton.filled(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                tooltip: loc.createCustomProfile,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (customProfiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                loc.noShiftsThisMonth,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.descriptionColor,
                  fontSize: 13,
                ),
              ),
            ),
          ...customProfiles.map(
            (p) => _ProfileTile(
              profile: p,
              isSystem: false,
              isOwner: widget.isOwner,
              onEdit: () => _showEditDialog(p),
              onDelete: () => _confirmDelete(p),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ShiftProfileEntity profile;
  final bool isSystem;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isSystem,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = profile.displayColor;
    final loc = AppLocalizations.of(context)!;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (profile.isPublic)
            Positioned(
              bottom: -4,
              right: -6,
              child: Icon(Icons.public, size: 10, color: Colors.blue.shade600),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(child: Text(profile.name, style: const TextStyle(fontSize: 14))),
          if (profile.isPublic) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 9, color: Colors.blue.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'Pubblico',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${profile.startTime.hour.toString().padLeft(2, '0')}:${profile.startTime.minute.toString().padLeft(2, '0')}'
        ' – '
        '${profile.endTime.hour.toString().padLeft(2, '0')}:${profile.endTime.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSystem
          ? Chip(
              label: Text(
                loc.systemProfile,
                style: const TextStyle(fontSize: 10),
              ),
              padding: EdgeInsets.zero,
            )
          : (profile.isPublic && !isOwner)
              ? const SizedBox.shrink()
              : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  tooltip: loc.editShiftProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: onDelete,
                  tooltip: loc.deleteShiftProfileConfirm,
                ),
              ],
            ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time, size: 16),
        ),
        child: Text(time.format(context)),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final String hex;
  const _ColorPreview({required this.hex});

  Color _parse() {
    final c = hex.replaceAll('#', '');
    if (c.length == 6) {
      return Color(int.tryParse('FF$c', radix: 16) ?? 0xFF4A90D9);
    }
    return const Color(0xFF4A90D9);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _parse(),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
