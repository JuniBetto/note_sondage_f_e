import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/theme_extensions.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';

class ShiftProfileManager extends StatefulWidget {
  final List<ShiftProfileEntity> profiles;
  final Set<String> syncingProfileIds;
  final bool isOwner;
  const ShiftProfileManager({
    super.key,
    required this.profiles,
    this.syncingProfileIds = const <String>{},
    this.isOwner = false,
  });

  @override
  State<ShiftProfileManager> createState() => _ShiftProfileManagerState();
}

class _ShiftProfileManagerState extends State<ShiftProfileManager> {
  static final List<String> _shiftPalette = _buildShiftPalette();

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
    String selectedColorHex = _normalizeHexColor(existing?.color ?? '#4A90D9');
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

    bool hasValidTimeRange() {
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      if (overnight) {
        return startMinutes != endMinutes;
      }
      return endMinutes > startMinutes;
    }

    void submitProfile(BuildContext dialogContext) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty || !hasValidTimeRange()) {
        return;
      }
      if (existing == null) {
        context.read<ShiftBloc>().add(
          CreateShiftProfileEvent(
            name: name,
            color: selectedColorHex,
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
            color: selectedColorHex,
            startTime: startTime,
            endTime: endTime,
            overnight: overnight,
            alarmOffsets: const [],
            isPublic: isPublic,
          ),
        );
      }
      Navigator.pop(dialogContext);
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final colorScheme = Theme.of(ctx).colorScheme;
          final canSubmit =
              nameCtrl.text.trim().isNotEmpty && hasValidTimeRange();
          return SubmitOnEnterScope(
            onSubmit: canSubmit ? () => submitProfile(ctx) : null,
            child: AlertDialog(
              title: Text(
                existing == null
                    ? loc.createCustomProfile
                    : loc.editShiftProfile,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) => setS(() {}),
                      decoration: InputDecoration(
                        labelText: loc.shiftProfileName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final pickedColor = await _pickShiftColor(
                          ctx,
                          initialHex: selectedColorHex,
                        );
                        if (pickedColor == null) return;
                        setS(() {
                          selectedColorHex = pickedColor;
                        });
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: loc.shiftColor,
                          border: const OutlineInputBorder(),
                          prefixIcon: _ColorPreview(hex: selectedColorHex),
                          suffixIcon: const Icon(Icons.expand_more_rounded),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedColorHex,
                                style: Theme.of(ctx).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _colorFromHex(selectedColorHex),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.borderColor!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    if (!hasValidTimeRange())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          loc.shiftEndMustBeAfterStart,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
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
                CustomAppButton(
                  onPressed: () => Navigator.pop(ctx),
                  type: ButtonType.text,
                  isActive: false,
                  child: Text(loc.cancel),
                ),
                CustomAppButton(
                  onPressed: !canSubmit ? null : () => submitProfile(ctx),
                  type: ButtonType.filled,
                  isActive: false,
                  child: Text(loc.save),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String?> _pickShiftColor(
    BuildContext context, {
    required String initialHex,
  }) async {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    if (isCompact) {
      return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => _ShiftColorPickerSheet(
          colors: _shiftPalette,
          selectedHex: initialHex,
        ),
      );
    }
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ShiftColorPickerSheet(
              colors: _shiftPalette,
              selectedHex: initialHex,
              showCloseButton: true,
            ),
          ),
        ),
      ),
    );
  }

  static String _normalizeHexColor(String value) {
    final hex = value.trim().replaceAll('#', '').toUpperCase();
    if (hex.length != 6) return '#4A90D9';
    final valid = RegExp(r'^[0-9A-F]{6}$').hasMatch(hex);
    return valid ? '#$hex' : '#4A90D9';
  }

  static Color _colorFromHex(String value) {
    final normalized = _normalizeHexColor(value);
    return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
  }

  static List<String> _buildShiftPalette() {
    const lightnessSteps = <double>[0.40, 0.50, 0.60, 0.70];
    const saturation = 0.78;
    final colors = <String>{};

    for (var hue = 0; hue < 360; hue += 20) {
      for (final lightness in lightnessSteps) {
        final color = HSLColor.fromAHSL(
          1,
          hue.toDouble(),
          saturation,
          lightness,
        ).toColor();
        colors.add(_hexFromColor(color));
      }
    }

    for (final grey in const [
      Color(0xFF111827),
      Color(0xFF334155),
      Color(0xFF475569),
      Color(0xFF64748B),
      Color(0xFF94A3B8),
      Color(0xFFCBD5E1),
    ]) {
      colors.add(_hexFromColor(grey));
    }

    return colors.toList(growable: false);
  }

  static String _hexFromColor(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _confirmDelete(ShiftProfileEntity profile) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteShiftProfileConfirm),
        actions: [
          CustomAppButton(
            onPressed: () => Navigator.pop(ctx, false),
            type: ButtonType.text,
            isActive: false,
            child: Text(loc.cancel),
          ),
          CustomAppButton(
            onPressed: () => Navigator.pop(ctx, true),
            type: ButtonType.filled,
            backgroundColor: Theme.of(ctx).colorScheme.error,
            isActive: true,
            child: Text(loc.removeAction),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      context.read<ShiftBloc>().add(DeleteShiftProfileEvent(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final systemProfiles = widget.profiles.where((p) => p.isSystem).toList();
    final customProfiles = widget.profiles.where((p) => !p.isSystem).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          loc.shiftProfile,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...systemProfiles.map(
                  (p) => _ProfileTile(
                    profile: p,
                    isSystem: true,
                    isSyncing: widget.syncingProfileIds.contains(p.id),
                  ),
                ),
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
                      icon: Icon(Icons.add, size: 18),
                      tooltip: loc.createCustomProfile,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.bgNavbarbutton,
                        foregroundColor: colorScheme.textInvertedColor,
                      ),
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
                    isSyncing: widget.syncingProfileIds.contains(p.id),
                    onEdit: () => _showEditDialog(p),
                    onDelete: () => _confirmDelete(p),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ShiftProfileEntity profile;
  final bool isSystem;
  final bool isOwner;
  final bool isSyncing;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isSystem,
    this.isOwner = false,
    this.isSyncing = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = profile.displayColor;
    final loc = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Opacity(
      opacity: isSyncing ? 0.78 : 1,
      child: ListTile(
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
                child: Icon(
                  Icons.public,
                  size: 10,
                  color: Colors.blue.shade600,
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(profile.name, style: const TextStyle(fontSize: 14)),
            ),
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
            if (isSyncing) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.34),
                  ),
                ),
                child: Text(
                  'Syncing',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w700,
                  ),
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
                  style: textTheme.bodySmall!.copyWith(
                    color: colorScheme.textColor,
                  ), //const TextStyle(fontSize: 10),
                ),
                backgroundColor: color,
                padding: EdgeInsets.zero,
                elevation: 6,
                shape: const StadiumBorder(),
                // Forma a stadio
                side: BorderSide.none,
              )
            : (profile.isPublic && !isOwner)
            ? const SizedBox.shrink()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: isSyncing ? null : onEdit,
                    tooltip: loc.editShiftProfile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: isSyncing ? null : onDelete,
                    tooltip: loc.deleteShiftProfileConfirm,
                  ),
                ],
              ),
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
    return _ShiftProfileManagerState._colorFromHex(hex);
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

class _ShiftColorPickerSheet extends StatelessWidget {
  final List<String> colors;
  final String selectedHex;
  final bool showCloseButton;

  const _ShiftColorPickerSheet({
    required this.colors,
    required this.selectedHex,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.shiftColor,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showCloseButton)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isCompact ? 360 : 400,
              minWidth: double.infinity,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompact ? 5 : 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final hex = colors[index];
                final color = _ShiftProfileManagerState._colorFromHex(hex);
                final isSelected = hex == selectedHex;
                final onColor =
                    ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black87;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).pop(hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.borderColor!,
                        width: isSelected ? 3 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: onColor,
                              size: 22,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
