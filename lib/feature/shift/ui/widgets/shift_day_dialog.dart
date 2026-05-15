import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// A simplified view of a team member used inside the shift dialog.
class ShiftTeamMember {
  final String? userId; // Firebase UID when assignable
  final String displayName;
  final String? subtitle;
  final bool isAssignable;
  const ShiftTeamMember({
    required this.userId,
    required this.displayName,
    this.subtitle,
    this.isAssignable = true,
  });
}

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
    this.archived = false,
    this.isPublic = false,
    this.teamId,
    this.targetUserIds = const [],
    this.scheduledDates = const [],
  });

  final String? profileId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final List<int> alarmOffsets;
  final String? note;
  final bool deleted;
  final bool archived;

  /// True → shift visible to all team members.
  final bool isPublic;
  final String? teamId;

  /// Firebase UIDs of the users who should receive this shift.
  /// Empty = assign only to the authenticated user (private).
  /// One entry = assign to that specific member.
  /// Multiple entries = assign to all selected members.
  final List<String> targetUserIds;

  /// Days on which the shift should be created.
  final List<DateTime> scheduledDates;
}

/// Modal bottom-sheet / dialog for assigning or editing a shift on a single day.
Future<ShiftDayDialogResult?> showShiftDayDialog({
  required BuildContext context,
  required DateTime date,
  required List<ShiftProfileEntity> profiles,
  ShiftAssignmentEntity? existing,
  bool canManagePublicShifts = false,

  /// Teams where the current user is owner (to enable team assignment).
  List<TeamEntityForView> ownerTeams = const [],
}) {
  final isWideLayout = MediaQuery.of(context).size.width >= 720;
  final sheet = _ShiftDaySheet(
    date: date,
    profiles: profiles,
    existing: existing,
    canManagePublicShifts: canManagePublicShifts,
    ownerTeams: ownerTeams,
    useDialogLayout: isWideLayout,
  );

  if (isWideLayout) {
    return showDialog<ShiftDayDialogResult>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: sheet,
      ),
    );
  }

  return showModalBottomSheet<ShiftDayDialogResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

class _ShiftDaySheet extends StatefulWidget {
  const _ShiftDaySheet({
    required this.date,
    required this.profiles,
    this.existing,
    this.canManagePublicShifts = false,
    this.ownerTeams = const [],
    this.useDialogLayout = false,
  });

  final DateTime date;
  final List<ShiftProfileEntity> profiles;
  final ShiftAssignmentEntity? existing;
  final bool canManagePublicShifts;
  final List<TeamEntityForView> ownerTeams;
  final bool useDialogLayout;

  @override
  State<_ShiftDaySheet> createState() => _ShiftDaySheetState();
}

class _ShiftDaySheetState extends State<_ShiftDaySheet> {
  final TeamMemberUseCase _teamMemberUseCase =
      GetIt.instance<TeamMemberUseCase>();
  final LocalNotificationService _localNotifications =
      GetIt.instance<LocalNotificationService>();

  ShiftProfileEntity? _selectedProfile;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _overnight;
  late List<int> _alarmOffsets;
  ShiftAlarmType _alarmType = ShiftAlarmType.alarm;
  late bool _isPublic;
  late bool _readOnly;
  late DateTime _rangeEndDate;
  final _noteCtrl = TextEditingController();
  final Map<String, List<TeamMemberforView>> _membersByTeamId =
      <String, List<TeamMemberforView>>{};
  final Set<String> _loadingTeamIds = <String>{};

  // ── Team assignment state ──────────────────────────────────────────────────
  TeamEntityForView? _selectedTeam;
  final Set<String> _selectedMemberIds = <String>{};
  bool _assignToAllMembers = true;

  bool get _hasOwnerTeams => widget.ownerTeams.isNotEmpty;
  bool get _isTeamScopedSelection => _selectedTeam != null;
  bool get _effectiveIsPublic => _isTeamScopedSelection || _isPublic;
  bool get _isSelectedTeamLoading {
    final teamId = _selectedTeam?.team.id;
    return teamId != null && _loadingTeamIds.contains(teamId);
  }

  List<ShiftTeamMember> get _teamMembers {
    if (_selectedTeam == null) return [];
    final members = _selectedTeam?.team.id != null
        ? (_membersByTeamId[_selectedTeam!.team.id!] ?? _selectedTeam!.members)
        : _selectedTeam!.members;
    return members.map((m) {
      final email = m.teamMember.userEmail.trim();
      final fullName = m.user?.fullName.trim() ?? '';
      final initialName = m.teamMember.initialName?.trim() ?? '';
      final displayName = fullName.isNotEmpty
          ? fullName
          : email.isNotEmpty
          ? email
          : initialName.isNotEmpty
          ? initialName
          : 'Membro del team';
      final subtitle = fullName.isNotEmpty && email.isNotEmpty
          ? email
          : m.teamMember.roleId.trim().isNotEmpty
          ? m.teamMember.roleId
          : null;
      final normalizedUserId = m.teamMember.userId?.trim();
      return ShiftTeamMember(
        userId: normalizedUserId?.isNotEmpty == true ? normalizedUserId : null,
        displayName: displayName,
        subtitle: subtitle,
        isAssignable: normalizedUserId?.isNotEmpty == true,
      );
    }).toList();
  }

  List<String> get _resolvedTargetUserIds {
    if (_selectedTeam == null) return [];
    if (_assignToAllMembers) {
      // all members
      return _teamMembers
          .where((m) => m.isAssignable && m.userId != null)
          .map((m) => m.userId!)
          .toList();
    }
    return _teamMembers
        .where(
          (member) =>
              member.userId != null &&
              _selectedMemberIds.contains(member.userId),
        )
        .map((member) => member.userId!)
        .toList();
  }

  bool get _hasValidTeamSelection {
    if (_selectedTeam == null) {
      return true;
    }
    if (_assignToAllMembers) {
      return _teamMembers.isNotEmpty;
    }
    return _selectedMemberIds.isNotEmpty;
  }

  bool get _hasValidTimeRange {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (_overnight) {
      return startMinutes != endMinutes;
    }
    return endMinutes > startMinutes;
  }

  List<DateTime> get _scheduledDates {
    final start = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final end = DateTime(
      _rangeEndDate.year,
      _rangeEndDate.month,
      _rangeEndDate.day,
    );
    final dates = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      dates.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return dates;
  }

  @override
  void initState() {
    super.initState();
    _loadAlarmType();
    for (final ownerTeam in widget.ownerTeams) {
      final teamId = ownerTeam.team.id;
      if (teamId != null && ownerTeam.members.isNotEmpty) {
        _membersByTeamId[teamId] = ownerTeam.members;
      }
    }

    if (widget.existing != null) {
      final ex = widget.existing!;
      _selectedProfile = widget.profiles
          .where((p) => p.id == ex.profileId)
          .firstOrNull;
      _startTime = ex.startTime;
      _endTime = ex.endTime;
      _overnight = ex.overnight;
      _alarmOffsets = List.from(ex.alarmOffsets);
      _isPublic = ex.isPublic;
      _rangeEndDate = widget.date;
      _noteCtrl.text = ex.note ?? '';
      if (ex.teamId != null) {
        _selectedTeam = widget.ownerTeams
            .where((team) => team.team.id == ex.teamId)
            .firstOrNull;
        // Pre-select the existing target member so an admin can see and
        // optionally change it when editing a team-scoped shift.
        if (ex.userId.isNotEmpty) {
          _assignToAllMembers = false;
          _selectedMemberIds.add(ex.userId);
        }
        unawaited(_ensureTeamMembersLoaded(_selectedTeam));
      }
    } else {
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = const TimeOfDay(hour: 16, minute: 0);
      _overnight = false;
      _alarmOffsets = [-30, -15];
      _isPublic = false;
      _rangeEndDate = widget.date;
    }
    // Non-owners cannot edit existing public shifts
    _readOnly =
        !widget.canManagePublicShifts &&
        widget.existing != null &&
        (widget.existing!.isPublic);
  }

  Future<void> _pickRangeEndDate(AppLocalizations loc) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEndDate,
      firstDate: DateTime(widget.date.year, widget.date.month, widget.date.day),
      lastDate: DateTime(widget.date.year + 2, 12, 31),
      helpText: loc.shiftRepeatUntil,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _rangeEndDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlarmType() async {
    final type = await _localNotifications.getShiftAlarmType();
    if (!mounted) return;
    setState(() => _alarmType = type);
  }

  /// Richiede i permessi Android necessari per la modalità Sveglia e mostra
  /// un dialog informativo se `USE_FULL_SCREEN_INTENT` non è concesso.
  Future<void> _requestAlarmPermissionsIfNeeded() async {
    if (kIsWeb) return;
    final status = await _localNotifications.requestAlarmModePermissions();
    if (!mounted) return;
    if (!status.fullScreenIntent) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permesso sveglia'),
          content: const Text(
            'Per far aprire lo schermo durante la sveglia del turno, '
            'abilita "Mostra sopra altre app" (o "Intent a schermo intero") '
            'nelle impostazioni dell\'app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _ensureTeamMembersLoaded(TeamEntityForView? team) async {
    final teamId = team?.team.id;
    if (teamId == null) {
      return;
    }
    if (_loadingTeamIds.contains(teamId)) {
      return;
    }
    setState(() {
      _loadingTeamIds.add(teamId);
    });
    try {
      final members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
      if (!mounted) return;
      setState(() {
        _loadingTeamIds.remove(teamId);
        _membersByTeamId[teamId] = members
            .map((member) => TeamMemberforView(teamMember: member))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTeamIds.remove(teamId);
      });
    }
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
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final appError = colorScheme.errorColor;
    final dialogBackground =
        colorScheme.dialogBackgroundColor ?? colorScheme.surface;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final mutedSurface =
        colorScheme.bgDialogSecondary?.withValues(alpha: 0.75) ??
        colorScheme.surface;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: widget.useDialogLayout ? 0 : 12,
        right: widget.useDialogLayout ? 0 : 12,
        top: widget.useDialogLayout ? 0 : 12,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            (widget.useDialogLayout ? 0 : 12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.useDialogLayout) ...[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
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
                    if (widget.existing != null && !_readOnly)
                      IconButton(
                        icon: Icon(
                          Icons.archive_outlined,
                          color: colorScheme.descriptionColor,
                        ),
                        tooltip: 'Archivia',
                        onPressed: () => Navigator.of(context).pop(
                          ShiftDayDialogResult(
                            startTime: _startTime,
                            endTime: _endTime,
                            overnight: _overnight,
                            alarmOffsets: _alarmOffsets,
                            archived: true,
                          ),
                        ),
                      ),
                    if (widget.existing != null && !_readOnly)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: appError),
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
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      tooltip: loc.close,
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Read-only banner (public shift, non-owner) ────────────────
                if (_readOnly)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: appPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: appPrimary.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.public, size: 16, color: appPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Turno pubblico – solo owner, admin o ruoli con permessi Admin/Manage possono modificarlo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: appPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      onTap: _readOnly ? null : () => _applyProfile(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? p.displayColor.withValues(alpha: 0.2)
                              : mutedSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? p.displayColor : borderColor,
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
                        readOnly: _readOnly,
                        onChanged: (t) => setState(() => _startTime = t),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePicker(
                        label: loc.shiftEnd,
                        value: _endTime,
                        readOnly: _readOnly,
                        onChanged: (t) => setState(() => _endTime = t),
                      ),
                    ),
                  ],
                ),const SizedBox(height: 16),
                if (!widget.useDialogLayout && widget.existing == null)
                  const SizedBox(height: 12),
                if (widget.existing == null)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _readOnly ? null : () => _pickRangeEndDate(loc),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.shiftRepeatUntil,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        helperText: loc.shiftRepeatUntilHelp,
                      ),
                      child: Text(_formatDateLabel(_rangeEndDate)),
                    ),
                  ),
                const SizedBox(height: 8),

                // ── Overnight toggle ──────────────────────────────────────────
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    loc.overnightShift,
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _overnight,
                  onChanged: _readOnly
                      ? null
                      : (v) => setState(() => _overnight = v),
                ),
                if (!_hasValidTimeRange)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      loc.shiftEndMustBeAfterStart,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: appError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  readOnly: _readOnly,
                  onChanged: (offsets) =>
                      setState(() => _alarmOffsets = offsets),
                ),
                const SizedBox(height: 8),

                // ── Alarm type toggle ─────────────────────────────────────────
                if (!_readOnly)
                  SegmentedButton<ShiftAlarmType>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: theme.textTheme.labelSmall,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ShiftAlarmType.notification,
                        label: Text('Notifica'),
                        icon: Icon(Icons.notifications_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ShiftAlarmType.alarm,
                        label: Text('Sveglia'),
                        icon: Icon(Icons.alarm, size: 16),
                      ),
                    ],
                    selected: {_alarmType},
                    onSelectionChanged: (newSet) {
                      final selected = newSet.first;
                      setState(() => _alarmType = selected);
                      unawaited(
                        _localNotifications.setShiftAlarmType(selected),
                      );
                      if (selected == ShiftAlarmType.alarm) {
                        unawaited(_requestAlarmPermissionsIfNeeded());
                      }
                    },
                  ),
                const SizedBox(height: 12),

                // ── Note ──────────────────────────────────────────────────────
                TextField(
                  controller: _noteCtrl,
                  readOnly: _readOnly,
                  decoration: InputDecoration(
                    labelText: loc.note,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                // ── Team assignment (managers: create + edit of public shifts) ──
                if (_hasOwnerTeams &&
                    (widget.existing == null ||
                        (widget.canManagePublicShifts &&
                            widget.existing!.isPublic))) ...[
                  const SizedBox(height: 12),
                  _TeamAssignmentSection(
                    ownerTeams: widget.ownerTeams,
                    selectedTeam: _selectedTeam,
                    selectedMemberIds: _selectedMemberIds,
                    assignToAllMembers: _assignToAllMembers,
                    teamMembers: _teamMembers,
                    isLoadingMembers: _isSelectedTeamLoading,
                    onTeamChanged: (team) {
                      setState(() {
                        _selectedTeam = team;
                        _assignToAllMembers = true;
                        _selectedMemberIds.clear();
                        if (team == null && widget.existing == null) {
                          _isPublic = false;
                        }
                      });
                      unawaited(_ensureTeamMembersLoaded(team));
                    },
                    onAssignToAllChanged: (value) => setState(() {
                      _assignToAllMembers = value;
                      if (value) {
                        _selectedMemberIds.clear();
                      }
                    }),
                    onMemberToggled: (uid, selected) => setState(() {
                      _assignToAllMembers = false;
                      if (selected) {
                        _selectedMemberIds.add(uid);
                      } else {
                        _selectedMemberIds.remove(uid);
                      }
                    }),
                  ),
                ],
                const SizedBox(height: 12),

                // ── Visibility toggle (owners only) ───────────────────────────
                if (widget.canManagePublicShifts || _effectiveIsPublic)
                  Container(
                    decoration: BoxDecoration(
                      color: _effectiveIsPublic
                          ? appPrimary.withValues(alpha: 0.08)
                          : mutedSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _effectiveIsPublic
                            ? appPrimary.withValues(alpha: 0.35)
                            : borderColor,
                      ),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      value: _effectiveIsPublic,
                      onChanged:
                          widget.canManagePublicShifts &&
                              !_isTeamScopedSelection
                          ? (v) => setState(() => _isPublic = v)
                          : null,
                      secondary: Icon(
                        _effectiveIsPublic ? Icons.public : Icons.lock_outline,
                        size: 18,
                        color: _effectiveIsPublic
                            ? appPrimary
                            : colorScheme.outline,
                      ),
                      title: Text(
                        _effectiveIsPublic
                            ? 'Pubblico – visibile al team'
                            : 'Privato – solo tu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _effectiveIsPublic ? appPrimary : null,
                        ),
                      ),
                      subtitle: Text(
                        _isTeamScopedSelection
                            ? 'Con un team selezionato il turno viene creato come pubblico'
                            : _effectiveIsPublic
                            ? 'Tutti i membri del team vedono questo turno'
                            : 'Solo tu puoi vedere questo turno',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Confirm / Close button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: _readOnly
                      ? OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(loc.close),
                        )
                      : FilledButton(
                          onPressed:
                              !_hasValidTeamSelection || !_hasValidTimeRange
                              ? null
                              : () async {
                                  if (_alarmOffsets.isNotEmpty &&
                                      _alarmType == ShiftAlarmType.alarm) {
                                    await _requestAlarmPermissionsIfNeeded();
                                    if (!mounted) {
                                      return;
                                    }
                                  }

                                  Navigator.of(context).pop(
                                    ShiftDayDialogResult(
                                      profileId: _selectedProfile?.id,
                                      startTime: _startTime,
                                      endTime: _endTime,
                                      overnight: _overnight,
                                      alarmOffsets: _alarmOffsets,
                                      note: _noteCtrl.text.trim().isEmpty
                                          ? null
                                          : _noteCtrl.text.trim(),
                                      isPublic: _effectiveIsPublic,
                                      teamId:
                                          _selectedTeam?.team.id ??
                                          widget.existing?.teamId,
                                      targetUserIds: _resolvedTargetUserIds,
                                      scheduledDates: _scheduledDates,
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: appPrimary,
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Section inside the shift dialog that lets an owner choose which team
/// (and which members) should receive the shift.
class _TeamAssignmentSection extends StatelessWidget {
  const _TeamAssignmentSection({
    required this.ownerTeams,
    required this.selectedTeam,
    required this.selectedMemberIds,
    required this.assignToAllMembers,
    required this.teamMembers,
    required this.isLoadingMembers,
    required this.onTeamChanged,
    required this.onAssignToAllChanged,
    required this.onMemberToggled,
  });

  final List<TeamEntityForView> ownerTeams;
  final TeamEntityForView? selectedTeam;
  final Set<String> selectedMemberIds;
  final bool assignToAllMembers;
  final List<ShiftTeamMember> teamMembers;
  final bool isLoadingMembers;
  final ValueChanged<TeamEntityForView?> onTeamChanged;
  final ValueChanged<bool> onAssignToAllChanged;
  final void Function(String uid, bool selected) onMemberToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assegna al team',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.descriptionColor,
          ),
        ),
        const SizedBox(height: 6),
        // ── Team dropdown ───────────────────────────────────────────────
        DropdownButtonFormField<TeamEntityForView?>(
          value: selectedTeam,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Privato (solo tu)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: [
            const DropdownMenuItem<TeamEntityForView?>(
              value: null,
              child: Text('Privato (solo tu)'),
            ),
            ...ownerTeams.map(
              (t) => DropdownMenuItem<TeamEntityForView?>(
                value: t,
                child: Row(
                  children: [
                    const Icon(Icons.group, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(t.team.name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onTeamChanged,
        ),
        // ── Member selector (visible only when a team is selected) ──────
        if (selectedTeam != null) ...[
          const SizedBox(height: 8),
          Text(
            'Assegna a',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.descriptionColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Puoi selezionare uno o piu membri specifici del team selezionato oppure assegnare il turno a tutti.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          ),
          const SizedBox(height: 8),
          // "All members" option
          _MemberRadioTile(
            uid: null,
            label: 'Tutti i membri del team',
            icon: Icons.groups_rounded,
            isSelected: assignToAllMembers,
            enabled: teamMembers.isNotEmpty,
            onTap: teamMembers.isEmpty
                ? null
                : () => onAssignToAllChanged(true),
          ),
          const SizedBox(height: 4),
          if (teamMembers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.bgDialogSecondary?.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      theme.colorScheme.borderColor ??
                      theme.colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  if (isLoadingMembers)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primaryColor,
                      ),
                    )
                  else
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.descriptionColor,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLoadingMembers
                          ? 'Caricamento membri del team...'
                          : 'Nessun membro disponibile per questo team.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          // Individual members
          ...teamMembers.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _MemberRadioTile(
                uid: m.userId,
                label: m.displayName,
                subtitle: m.subtitle,
                icon: Icons.person_outline_rounded,
                enabled: m.isAssignable,
                isSelected:
                    m.userId != null && selectedMemberIds.contains(m.userId),
                onTap: m.userId == null
                    ? null
                    : () => onMemberToggled(
                        m.userId!,
                        !selectedMemberIds.contains(m.userId),
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberRadioTile extends StatelessWidget {
  const _MemberRadioTile({
    required this.uid,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  final String? uid;
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final mutedSurface =
        colorScheme.bgDialogSecondary?.withValues(alpha: 0.75) ??
        colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: !enabled
              ? mutedSurface.withValues(alpha: 0.55)
              : isSelected
              ? appPrimary.withValues(alpha: 0.08)
              : mutedSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !enabled
                ? borderColor.withValues(alpha: 0.6)
                : isSelected
                ? appPrimary.withValues(alpha: 0.45)
                : borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: !enabled
                  ? colorScheme.outline.withValues(alpha: 0.65)
                  : isSelected
                  ? appPrimary
                  : colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: !enabled
                          ? colorScheme.descriptionColor
                          : isSelected
                          ? appPrimary
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (!enabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Non assegnabile finché l’utente non è attivo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 16, color: appPrimary),
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
    this.readOnly = false,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: readOnly
          ? null
          : () async {
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
          color: theme.colorScheme.bgDialogSecondary?.withValues(alpha: 0.45),
          border: Border.all(
            color: theme.colorScheme.borderColor ?? theme.colorScheme.outline,
          ),
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
  const _AlarmOffsetEditor({
    required this.offsets,
    required this.onChanged,
    this.readOnly = false,
  });

  final List<int> offsets;
  final ValueChanged<List<int>> onChanged;
  final bool readOnly;

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
            deleteIcon: readOnly ? null : const Icon(Icons.close, size: 14),
            onDeleted: readOnly
                ? null
                : () {
                    final updated = List<int>.from(offsets)..remove(offset);
                    onChanged(updated);
                  },
          );
        }),
        if (!readOnly)
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
