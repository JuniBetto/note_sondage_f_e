import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/utils/clocking_access_resolver.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/anchored_dropdown_overlay.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

class ButtonClocking extends StatefulWidget {
  const ButtonClocking({
    super.key,
    this.isCompact = false,
    this.selectedTeamId,
    this.selectedDate,
    this.onSelectedTeamChanged,
    this.onSelectedDateChanged,
  });

  final bool isCompact;
  final String? selectedTeamId;
  final DateTime? selectedDate;
  final ValueChanged<String?>? onSelectedTeamChanged;
  final ValueChanged<DateTime>? onSelectedDateChanged;

  @override
  State<ButtonClocking> createState() => _ButtonClockingState();
}

class _ButtonClockingState extends State<ButtonClocking> {
  final ClockingUseCase _clockingUseCase = getIt<ClockingUseCase>();
  final TeamMemberUseCase _teamMemberUseCase = getIt<TeamMemberUseCase>();
  final RoleUseCase _roleUseCase = getIt<RoleUseCase>();
  final TextEditingController _manualBreakController = TextEditingController(
    text: '0',
  );
  final TextEditingController _manualNoteController = TextEditingController();

  List<DateTime> _manualSelectedDates = const <DateTime>[];
  TimeOfDay _manualClockInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _manualClockOutTime = const TimeOfDay(hour: 18, minute: 0);
  bool _manualActionInProgress = false;
  bool _canManageClocking = false;
  String? _resolvedTeamId;
  final Set<DateTime> _dismissedManualEntryDates = {};

  DateTime get _effectiveSelectedDate =>
      _normalizeDate(widget.selectedDate ?? DateTime.now());

  String get _currentUserId => context.read<AuthBloc>().state.user.uid;
  String get _currentUserEmail => context.read<AuthBloc>().state.user.email;

  @override
  void initState() {
    super.initState();
    _syncManualDatesFromSelectedDate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncClockingAccess());
  }

  @override
  void didUpdateWidget(covariant ButtonClocking oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousDate = _normalizeDate(oldWidget.selectedDate ?? DateTime.now());
    if (!_isSameDay(previousDate, _effectiveSelectedDate)) {
      _syncManualDatesFromSelectedDate();
    }
    if (oldWidget.selectedTeamId != widget.selectedTeamId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncClockingAccess());
    }
  }

  @override
  void dispose() {
    _manualBreakController.dispose();
    _manualNoteController.dispose();
    super.dispose();
  }

  Future<void> _syncClockingAccess() async {
    final teamId = widget.selectedTeamId;
    if (!mounted) {
      return;
    }
    if (teamId == null || teamId.isEmpty) {
      if (_canManageClocking || _resolvedTeamId != null) {
        setState(() {
          _canManageClocking = false;
          _resolvedTeamId = null;
        });
      }
      return;
    }

    final teamState = context.read<TeamBloc>().state;
    TeamEntity? team;
    if (teamState is TeamsLoaded) {
      team = teamState.teams.cast<TeamEntity?>().firstWhere(
        (item) => item?.id == teamId,
        orElse: () => null,
      );
    }

    bool nextCanManage = false;
    try {
      nextCanManage = await ClockingAccessResolver.canManageClocking(
        team: team,
        currentUserId: _currentUserId,
        currentUserEmail: _currentUserEmail,
        teamMemberUseCase: _teamMemberUseCase,
        roleUseCase: _roleUseCase,
      );
    } catch (_) {}

    if (!mounted) {
      return;
    }
    setState(() {
      _canManageClocking = nextCanManage;
      _resolvedTeamId = teamId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return BlocListener<ClockingBloc, ClockingState>(
      listenWhen: (previous, current) => current is ClockingError,
      listener: (context, state) {
        if (state is! ClockingError) return;
        AppSnackBar.showError(context, state.message);
      },
      child: BlocBuilder<TeamBloc, TeamState>(
        builder: (context, teamState) {
          final teams = teamState is TeamsLoaded ? teamState.teams : <TeamEntity>[];
          _ensureSelectedTeam(teams);
          if (widget.selectedTeamId != _resolvedTeamId) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _syncClockingAccess());
          }

          return BlocBuilder<ClockingBloc, ClockingState>(
            builder: (context, clockingState) {
              final records = _extractMyRecords(clockingState);
              final recordsForSelectedDate = _recordsForDate(
                records,
                _effectiveSelectedDate,
              );
              final selectedDateRecord = _recordForDate(
                records,
                _effectiveSelectedDate,
              );
              final activeRecordForSelectedDate = recordsForSelectedDate
                  .cast<ClockingRecordEntity?>()
                  .firstWhere((record) => record?.isActive == true, orElse: () => null);
              final activeRecord = _activeRecord(records);
              final hasOpenRecordOutsideSelectedDate =
                  activeRecord != null && activeRecordForSelectedDate == null;
              final selectedDateIsToday = _isSameDay(
                _effectiveSelectedDate,
                _normalizeDate(DateTime.now()),
              );
              final isBusy =
                  clockingState is ClockingActionInProgress || _manualActionInProgress;
              final isClockingReady =
                  clockingState is ClockingRecordsLoaded ||
                  clockingState is ClockingActionInProgress ||
                  clockingState is ClockingActionSuccess;
              final hasSelectedTeam =
                  widget.selectedTeamId != null && widget.selectedTeamId!.isNotEmpty;
              final hasApprovedManualClockingRequest =
                  _hasApprovedManualClockingRequest(context);
              final hasVacationOnSelectedDate = recordsForSelectedDate.any(
                (record) => record.isVacation,
              );
              final useManualEntryMode =
                  !selectedDateIsToday &&
                  !hasVacationOnSelectedDate &&
                  !_dismissedManualEntryDates.contains(_effectiveSelectedDate) &&
                  (!hasSelectedTeam ||
                      _canManageClocking ||
                      hasApprovedManualClockingRequest);
              final requiresApprovalForPastDate =
                  hasSelectedTeam &&
                  !selectedDateIsToday &&
                  !hasVacationOnSelectedDate &&
                  !_canManageClocking &&
                  !hasApprovedManualClockingRequest;

              final clockColor =
                  activeRecordForSelectedDate != null ? Colors.red : Colors.green;
              final breakColor =
                  activeRecordForSelectedDate?.isOnBreak == true
                  ? Colors.orange
                  : Colors.blue;

              if (useManualEntryMode) {
                return _buildManualEntrySection(
                  records: records,
                  hasVacationOnSelectedDate: hasVacationOnSelectedDate,
                  hasOpenRecordOutsideSelectedDate: hasOpenRecordOutsideSelectedDate,
                  isClockingReady: isClockingReady,
                );
              }

              final actionButtons = widget.isCompact
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8.0,
                      children: [
                        _ClockActionButton(
                          onTap:
                              !isBusy &&
                                  isClockingReady &&
                                  !requiresApprovalForPastDate &&
                                  !hasOpenRecordOutsideSelectedDate &&
                                  !hasVacationOnSelectedDate
                              ? () => _onClockAction(activeRecordForSelectedDate)
                              : null,
                          color: clockColor,
                          icon: activeRecordForSelectedDate != null
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          label: activeRecordForSelectedDate != null
                              ? localization.clockedOutAt
                                    .replaceAll(':', '')
                                    .trim()
                              : localization.clockedInAt
                                    .replaceAll(':', '')
                                    .trim(),
                          subtitle: _primaryActionSubtitle(
                            localization: localization,
                            activeRecordForSelectedDate: activeRecordForSelectedDate,
                            hasOpenRecordOutsideSelectedDate:
                                hasOpenRecordOutsideSelectedDate,
                            selectedDateRecord: selectedDateRecord,
                            hasVacationOnSelectedDate: hasVacationOnSelectedDate,
                            isClockingReady: isClockingReady,
                            selectedDateIsToday: selectedDateIsToday,
                            hasApprovedManualClockingRequest:
                                hasApprovedManualClockingRequest,
                          ),
                          isCompact: true,
                          isDisabled:
                              isBusy ||
                              !isClockingReady ||
                              requiresApprovalForPastDate ||
                              hasOpenRecordOutsideSelectedDate ||
                              hasVacationOnSelectedDate,
                        ),
                        const SizedBox(height: 12),
                        _ClockActionButton(
                          onTap:
                              activeRecordForSelectedDate != null &&
                                  selectedDateIsToday &&
                                  !isBusy &&
                                  isClockingReady
                              ? () => _onBreakAction(activeRecordForSelectedDate)
                              : null,
                          color: breakColor,
                          icon: Icons.coffee_rounded,
                          label:
                              (activeRecordForSelectedDate?.isOnBreak == true
                                      ? localization.endBreakAt
                                      : localization.startBreakAt)
                                  .replaceAll(':', '')
                                  .trim(),
                          subtitle: activeRecordForSelectedDate == null
                              ? _breakSubtitle(
                                  localization,
                                  selectedDateIsToday: selectedDateIsToday,
                                  hasVacationOnSelectedDate:
                                      hasVacationOnSelectedDate,
                                )
                              : (activeRecordForSelectedDate.isOnBreak
                                    ? localization.endActiveBreak
                                    : localization.startActiveBreak),
                          isCompact: true,
                          isDisabled:
                              activeRecordForSelectedDate == null ||
                              !selectedDateIsToday ||
                              isBusy ||
                              !isClockingReady,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _ClockActionButton(
                            onTap:
                                !isBusy &&
                                    isClockingReady &&
                                    !requiresApprovalForPastDate &&
                                    !hasOpenRecordOutsideSelectedDate &&
                                    !hasVacationOnSelectedDate
                                ? () => _onClockAction(activeRecordForSelectedDate)
                                : null,
                            color: clockColor,
                            icon: activeRecordForSelectedDate != null
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            label: activeRecordForSelectedDate != null
                                ? localization.clockedOutAt
                                      .replaceAll(':', '')
                                      .trim()
                                : localization.clockedInAt
                                      .replaceAll(':', '')
                                      .trim(),
                            subtitle: _primaryActionSubtitle(
                              localization: localization,
                              activeRecordForSelectedDate:
                                  activeRecordForSelectedDate,
                              hasOpenRecordOutsideSelectedDate:
                                  hasOpenRecordOutsideSelectedDate,
                              selectedDateRecord: selectedDateRecord,
                              hasVacationOnSelectedDate: hasVacationOnSelectedDate,
                              isClockingReady: isClockingReady,
                              selectedDateIsToday: selectedDateIsToday,
                              hasApprovedManualClockingRequest:
                                  hasApprovedManualClockingRequest,
                            ),
                            isCompact: false,
                            isDisabled:
                                isBusy ||
                                !isClockingReady ||
                                requiresApprovalForPastDate ||
                                hasOpenRecordOutsideSelectedDate ||
                                hasVacationOnSelectedDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ClockActionButton(
                            onTap:
                                activeRecordForSelectedDate != null &&
                                    selectedDateIsToday &&
                                    !isBusy &&
                                    isClockingReady
                                ? () => _onBreakAction(activeRecordForSelectedDate)
                                : null,
                            color: breakColor,
                            icon: Icons.coffee_rounded,
                            label:
                                (activeRecordForSelectedDate?.isOnBreak == true
                                        ? localization.endBreakAt
                                        : localization.startBreakAt)
                                    .replaceAll(':', '')
                                    .trim(),
                            subtitle: activeRecordForSelectedDate == null
                                ? _breakSubtitle(
                                    localization,
                                    selectedDateIsToday: selectedDateIsToday,
                                    hasVacationOnSelectedDate:
                                        hasVacationOnSelectedDate,
                                  )
                                : (activeRecordForSelectedDate.isOnBreak
                                      ? localization.endActiveBreak
                                      : localization.startActiveBreak),
                            isCompact: false,
                            isDisabled:
                                activeRecordForSelectedDate == null ||
                                !selectedDateIsToday ||
                                isBusy ||
                                !isClockingReady,
                          ),
                        ),
                      ],
                    );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ClockingTeamSelector(
                    isCompact: widget.isCompact,
                    teams: teams,
                    selectedTeamId: widget.selectedTeamId,
                    onChanged: widget.onSelectedTeamChanged ?? (_) {},
                  ),
                  const SizedBox(height: 12),
                  actionButtons,
                  if (widget.selectedTeamId == null || widget.selectedTeamId!.isEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localization.personal,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomAppButton(
                        onPressed:
                            activeRecord == null &&
                                !isBusy &&
                                isClockingReady &&
                                !requiresApprovalForPastDate &&
                                !hasVacationOnSelectedDate
                            ? _onVacationAction
                            : null,
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: true,
                        leadingIcon: const Icon(Icons.beach_access_rounded),
                        child: Text(localization.markVacation),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomAppButton(
                        onPressed:
                            !isBusy &&
                                isClockingReady &&
                                !requiresApprovalForPastDate &&
                                !hasVacationOnSelectedDate
                            ? _onPermissionAction
                            : null,
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: true,
                        leadingIcon: const Icon(Icons.schedule_rounded),
                        child: Text(localization.markPermission),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _ensureSelectedTeam(List<TeamEntity> teams) {
    if (teams.isEmpty) {
      if (widget.selectedTeamId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onSelectedTeamChanged?.call(null);
        });
      }
      return;
    }

    final teamIds = teams.map((team) => team.id).whereType<String>().toSet();
    if (widget.selectedTeamId != null &&
        !teamIds.contains(widget.selectedTeamId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onSelectedTeamChanged?.call(null);
      });
    }
  }

  List<ClockingRecordEntity> _extractMyRecords(ClockingState state) {
    if (state is ClockingRecordsLoaded) return state.myRecords;
    if (state is ClockingActionInProgress) return state.myRecords;
    if (state is ClockingActionSuccess) return state.myRecords;
    return const [];
  }

  ClockingRecordEntity? _activeRecord(List<ClockingRecordEntity> records) {
    for (final record in records) {
      if (record.isActive) {
        return record;
      }
    }
    return null;
  }

  ClockingRecordEntity? _recordForDate(
    List<ClockingRecordEntity> records,
    DateTime selectedDate,
  ) {
    final recordsForDate = _recordsForDate(records, selectedDate);
    for (final record in recordsForDate) {
      if (record.isActive) {
        return record;
      }
    }
    return recordsForDate.isEmpty ? null : recordsForDate.first;
  }

  List<ClockingRecordEntity> _recordsForDate(
    List<ClockingRecordEntity> records,
    DateTime selectedDate,
  ) {
    final filtered = records
        .where((record) => _isSameDay(record.date, selectedDate))
        .toList()
      ..sort((a, b) => _recordSortDate(b).compareTo(_recordSortDate(a)));
    return filtered;
  }

  DateTime _recordSortDate(ClockingRecordEntity record) {
    return record.clockOutTime ??
        record.currentBreakStartedAt ??
        record.clockInTime ??
        record.date;
  }

  void _onClockAction(ClockingRecordEntity? activeRecord) {
    if (activeRecord == null) {
      context.read<ClockingBloc>().add(
        ClockInEvent(
          teamId: widget.selectedTeamId,
          clockInAt: _resolvedActionDateTime(_effectiveSelectedDate),
        ),
      );
      return;
    }
    _showClockOutNoteDialog(activeRecord);
  }

  void _onBreakAction(ClockingRecordEntity activeRecord) {
    if (activeRecord.isOnBreak) {
      context.read<ClockingBloc>().add(StopBreakEvent(teamId: activeRecord.teamId));
      return;
    }
    context.read<ClockingBloc>().add(StartBreakEvent(teamId: activeRecord.teamId));
  }

  Future<void> _showClockOutNoteDialog(ClockingRecordEntity activeRecord) async {
    final localization = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: activeRecord.note ?? '');
    final note = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localization.clockedOutAt.replaceAll(':', '').trim()),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: localization.note,
            hintText: localization.optionalNoteHint,
          ),
        ),
        actions: [
          CustomAppButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            type: ButtonType.text,
            isActive: false,
            child: Text(localization.cancel),
          ),
          CustomAppButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            type: ButtonType.filled,
            isActive: true,
            child: Text(localization.save),
          ),
        ],
      ),
    );

    if (!mounted || note == null) return;
    context.read<ClockingBloc>().add(
      ClockOutEvent(
        teamId: activeRecord.teamId,
        note: note.isEmpty ? null : note,
        clockOutAt: _resolvedActionDateTime(
          _effectiveSelectedDate,
          minimum: activeRecord.clockInTime,
        ),
      ),
    );
  }

  Future<void> _onVacationAction() async {
    final localization = AppLocalizations.of(context)!;
    if (_requiresManagerApprovalForSelectedDate()) {
      AppSnackBar.showWarning(context, localization.manualClockingRequiresApproval);
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          localization.markSelectedDateAsVacation(
            _formatDateLabel(_effectiveSelectedDate),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.markSelectedDayAsVacationDescription),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: localization.note,
                hintText: localization.optionalNoteHint,
              ),
            ),
          ],
        ),
        actions: [
          CustomAppButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            type: ButtonType.text,
            isActive: false,
            child: Text(localization.cancel),
          ),
          CustomAppButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            type: ButtonType.filled,
            isActive: true,
            child: Text(localization.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<ClockingBloc>().add(
      MarkVacationEvent(
        teamId: widget.selectedTeamId,
        date: _effectiveSelectedDate,
        note: controller.text.trim().isEmpty ? null : controller.text.trim(),
      ),
    );
  }

  Future<void> _onPermissionAction() async {
    final localization = AppLocalizations.of(context)!;
    if (_requiresManagerApprovalForSelectedDate()) {
      AppSnackBar.showWarning(context, localization.manualClockingRequiresApproval);
      return;
    }

    TimeOfDay start = const TimeOfDay(hour: 12, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 14, minute: 0);
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            localization.markPermissionForDate(_formatDateLabel(_effectiveSelectedDate)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomAppButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: start,
                          );
                          if (picked == null) return;
                          setDialogState(() => start = picked);
                        },
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: true,
                        child: Text('${localization.start}: ${start.format(dialogContext)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomAppButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: end,
                          );
                          if (picked == null) return;
                          setDialogState(() => end = picked);
                        },
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: true,
                        child: Text('${localization.end}: ${end.format(dialogContext)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: localization.note,
                    hintText: localization.optionalNoteHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              type: ButtonType.text,
              isActive: false,
              child: Text(localization.cancel),
            ),
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              type: ButtonType.filled,
              isActive: true,
              child: Text(localization.save),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final startMinutes = (start.hour * 60) + start.minute;
    final endMinutes = (end.hour * 60) + end.minute;
    if (endMinutes <= startMinutes) {
      AppSnackBar.showWarning(context, localization.permissionInvalidRange);
      return;
    }

    context.read<ClockingBloc>().add(
      MarkPermissionEvent(
        teamId: widget.selectedTeamId,
        date: _effectiveSelectedDate,
        startTime:
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
        endTime:
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      ),
    );
  }

  bool _hasApprovedManualClockingRequest(BuildContext context) {
    final teamId = widget.selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      return false;
    }
    final notifications = context.watch<NotificationCenterCubit>().state.notifications;
    for (final item in notifications) {
      if (item.supportsApprovedManualClockingFor(
        currentUserId: _currentUserId,
        teamId: teamId,
        date: _effectiveSelectedDate,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _requiresManagerApprovalForSelectedDate() {
    final hasSelectedTeam =
        widget.selectedTeamId != null && widget.selectedTeamId!.isNotEmpty;
    final selectedDateIsToday = _isSameDay(
      _effectiveSelectedDate,
      _normalizeDate(DateTime.now()),
    );
    if (!hasSelectedTeam || selectedDateIsToday) {
      return false;
    }
    return !_canManageClocking && !_hasApprovedManualClockingRequest(context);
  }

  String _primaryActionSubtitle({
    required AppLocalizations localization,
    required ClockingRecordEntity? activeRecordForSelectedDate,
    required bool hasOpenRecordOutsideSelectedDate,
    required ClockingRecordEntity? selectedDateRecord,
    required bool hasVacationOnSelectedDate,
    required bool isClockingReady,
    required bool selectedDateIsToday,
    required bool hasApprovedManualClockingRequest,
  }) {
    if (hasOpenRecordOutsideSelectedDate) {
      return localization.clockingOpenRecordAnotherDay;
    }
    if (!selectedDateIsToday) {
      final hasSelectedTeam =
          widget.selectedTeamId != null && widget.selectedTeamId!.isNotEmpty;
      if (hasSelectedTeam &&
          !_canManageClocking &&
          !hasApprovedManualClockingRequest) {
        return localization.manualClockingRequiresApproval;
      }
      if (hasVacationOnSelectedDate) {
        return localization.selectedDayMarkedAsVacation;
      }
      return localization.manualClockingUseInlineForPastDays;
    }
    if (hasVacationOnSelectedDate || selectedDateRecord?.isVacation == true) {
      return localization.selectedDayMarkedAsVacation;
    }
    if (activeRecordForSelectedDate != null) {
      return localization.activeTurnOn(activeRecordForSelectedDate.teamName);
    }
    if (!isClockingReady) {
      return localization.loadingClockingState;
    }
    return localization.openYourTurn;
  }

  String _breakSubtitle(
    AppLocalizations localization, {
    required bool selectedDateIsToday,
    required bool hasVacationOnSelectedDate,
  }) {
    if (hasVacationOnSelectedDate) {
      return localization.selectedDayMarkedAsVacation;
    }
    if (!selectedDateIsToday) {
      return localization.breakOnlyCurrentDay;
    }
    return localization.clockInRequiredForBreak;
  }

  Widget _buildManualEntrySection({
    required List<ClockingRecordEntity> records,
    required bool hasVacationOnSelectedDate,
    required bool hasOpenRecordOutsideSelectedDate,
    required bool isClockingReady,
  }) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;
    final hasConflict = hasVacationOnSelectedDate || hasOpenRecordOutsideSelectedDate;
    final useWideLayout = !widget.isCompact;

    final dateSelector = Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _manualSelectedDates
                .map(
                  (date) => InputChip(
                    label: Text(_formatDateLabel(date)),
                    onDeleted: _manualSelectedDates.length == 1
                        ? null
                        : () => _removeManualDate(date),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: hasConflict || !isClockingReady || _manualActionInProgress
              ? null
              : () => _addManualDate(records),
          icon: const Icon(Icons.add_rounded),
          tooltip: localization.addDay,
        ),
      ],
    );

    final timeSelectors = Row(
      children: [
        Expanded(
          child: CustomAppButton(
            onPressed: hasConflict || !isClockingReady || _manualActionInProgress
                ? null
                : () => _pickManualTime(isClockIn: true),
            type: ButtonType.outlined,
            isActive: true,
            fullWidth: true,
            child: Text(
              '${localization.clockInLabel}: ${_manualClockInTime.format(context)}',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomAppButton(
            onPressed: hasConflict || !isClockingReady || _manualActionInProgress
                ? null
                : () => _pickManualTime(isClockIn: false),
            type: ButtonType.outlined,
            isActive: true,
            fullWidth: true,
            child: Text(
              '${localization.clockOutLabel}: ${_manualClockOutTime.format(context)}',
            ),
          ),
        ),
      ],
    );

    final breakField = TextField(
      controller: _manualBreakController,
      keyboardType: TextInputType.number,
      enabled: !hasConflict && isClockingReady && !_manualActionInProgress,
      decoration: InputDecoration(
        labelText: localization.breakMinutes,
        hintText: '0',
        filled: true,
        fillColor: theme.colorScheme.surface,
        prefixIcon: const Icon(Icons.timer_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    final noteField = TextField(
      controller: _manualNoteController,
      maxLines: 3,
      enabled: !hasConflict && isClockingReady && !_manualActionInProgress,
      decoration: InputDecoration(
        labelText: localization.note,
        hintText: localization.optionalNoteHint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    final actionButtons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomAppButton(
          onPressed: hasConflict || !isClockingReady || _manualActionInProgress
              ? null
              : () => _saveManualClockingEntries(records),
          type: ButtonType.filled,
          isActive: true,
          fullWidth: true,
          leadingIcon: const Icon(Icons.save_rounded),
          isLoading: _manualActionInProgress,
          child: Text(
            _manualActionInProgress
                ? localization.saving
                : localization.saveClocking,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.selectedTeamId == null || widget.selectedTeamId!.isEmpty) ...[
          CustomAppButton(
            onPressed:
                !hasVacationOnSelectedDate &&
                    !hasOpenRecordOutsideSelectedDate &&
                    isClockingReady &&
                    !_manualActionInProgress
                ? _onVacationAction
                : null,
            type: ButtonType.outlined,
            isActive: true,
            fullWidth: true,
            leadingIcon: const Icon(Icons.beach_access_rounded),
            child: Text(localization.markVacation),
          ),
          const SizedBox(height: 12),
          CustomAppButton(
            onPressed:
                isClockingReady &&
                    !_manualActionInProgress &&
                    !hasVacationOnSelectedDate
                ? _onPermissionAction
                : null,
            type: ButtonType.outlined,
            isActive: true,
            fullWidth: true,
            leadingIcon: const Icon(Icons.schedule_rounded),
            child: Text(localization.markPermission),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClockingTeamSelector(
          isCompact: widget.isCompact,
          teams: context.read<TeamBloc>().state is TeamsLoaded
              ? (context.read<TeamBloc>().state as TeamsLoaded).teams
              : const <TeamEntity>[],
          selectedTeamId: widget.selectedTeamId,
          onChanged: widget.onSelectedTeamChanged ?? (_) {},
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.bgNavbarSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.manualClockingTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localization.manualClockingDescription(
                            _formatDateLabel(_effectiveSelectedDate),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onSelectedDateChanged != null)
                    IconButton(
                      onPressed: () => _confirmCloseManualEntry(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Torna ad oggi',
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (hasOpenRecordOutsideSelectedDate) ...[
                const SizedBox(height: 10),
                Text(
                  localization.manualClockingResolveOpenRecord,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else if (hasVacationOnSelectedDate) ...[
                const SizedBox(height: 10),
                Text(
                  localization.selectedDayMarkedAsVacation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (useWideLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          dateSelector,
                          const SizedBox(height: 12),
                          timeSelectors,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          breakField,
                          const SizedBox(height: 12),
                          noteField,
                          const SizedBox(height: 14),
                          actionButtons,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                dateSelector,
                const SizedBox(height: 12),
                timeSelectors,
                const SizedBox(height: 12),
                breakField,
                const SizedBox(height: 12),
                noteField,
                const SizedBox(height: 14),
                actionButtons,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveManualClockingEntries(List<ClockingRecordEntity> records) async {
    final localization = AppLocalizations.of(context)!;
    final selectedDate = _effectiveSelectedDate;
    final today = _normalizeDate(DateTime.now());
    if (_isSameDay(selectedDate, today)) {
      AppSnackBar.showWarning(context, localization.manualClockingTodayLiveOnly);
      return;
    }

    final vacationDates = records
        .where((record) => record.isVacation)
        .map((record) => _normalizeDate(record.date))
        .toSet();
    final conflictingDate = _manualSelectedDates.cast<DateTime?>().firstWhere(
      (date) => date != null && vacationDates.contains(_normalizeDate(date)),
      orElse: () => null,
    );
    if (conflictingDate != null) {
      AppSnackBar.showWarning(context, localization.selectedDayMarkedAsVacation);
      return;
    }

    final breakMinutes = int.tryParse(_manualBreakController.text.trim()) ?? -1;
    final clockInMinutes = _timeOfDayToMinutes(_manualClockInTime);
    final clockOutMinutes = _timeOfDayToMinutes(_manualClockOutTime);
    if (breakMinutes < 0) {
      AppSnackBar.showWarning(context, localization.invalidBreakMinutes);
      return;
    }
    if (clockOutMinutes <= clockInMinutes) {
      AppSnackBar.showWarning(context, localization.clockOutMustBeAfterClockIn);
      return;
    }
    if (breakMinutes >= (clockOutMinutes - clockInMinutes)) {
      AppSnackBar.showWarning(
        context,
        localization.breakMustBeShorterThanShift,
      );
      return;
    }

    // ── Overlap detection ──────────────────────────────────────────────────
    // For each selected date, check if an existing completed record overlaps.
    for (final date in _manualSelectedDates) {
      final newClockIn = date.add(Duration(minutes: clockInMinutes));
      final newClockOut = date.add(Duration(minutes: clockOutMinutes));

      final overlapping = records.where((rec) {
        if (rec.isVacation) return false;
        final recIn = rec.clockInTime;
        final recOut = rec.clockOutTime;
        if (recIn == null || recOut == null) return false;
        // Overlap: the two intervals intersect
        return recIn.isBefore(newClockOut) && recOut.isAfter(newClockIn);
      }).toList();

      if (overlapping.isEmpty) continue;

      // Show one dialog per conflicting record (usually just one)
      for (final conflicting in overlapping) {
        final recInLabel = _formatTimeLabel(conflicting.clockInTime!);
        final recOutLabel = _formatTimeLabel(conflicting.clockOutTime!);
        final newInLabel = _formatTimeLabel(newClockIn);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sovrapposizione rilevata'),
            content: Text(
              'La nuova timbratura (${_formatTimeLabel(newClockIn)} – ${_formatTimeLabel(newClockOut)}) '
              'si sovrappone con una timbratura esistente ($recInLabel – $recOutLabel).\n\n'
              'Vuoi ridurre la timbratura esistente facendola terminare alle $newInLabel?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sì, riduci'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (confirmed != true) return;

        // Trim the existing record's clock-out to newClockIn
        try {
          await _clockingUseCase.updateTeamRecord(
            id: conflicting.id,
            clockOutAt: newClockIn,
          );
        } catch (_) {
          // If updateTeamRecord fails (e.g. personal record), just proceed
        }
      }
    }
    // ─────────────────────────────────────────────────────────────────────

    setState(() => _manualActionInProgress = true);
    try {
      final createdCount = await _clockingUseCase.createManualClockingEntries(
        teamId: widget.selectedTeamId,
        dates: _manualSelectedDates,
        clockInMinutes: clockInMinutes,
        clockOutMinutes: clockOutMinutes,
        breakMinutes: breakMinutes,
        note: _manualNoteController.text.trim().isEmpty
            ? null
            : _manualNoteController.text.trim(),
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        createdCount == 1
            ? localization.manualClockingSavedSingle
            : localization.manualClockingSavedMultiple(createdCount),
      );
      context.read<ClockingBloc>().add(
        LoadClockingRecordsEvent(teamId: widget.selectedTeamId),
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: localization.manualClockingSaveError,
      );
    } finally {
      if (mounted) {
        setState(() => _manualActionInProgress = false);
      }
    }
  }

  DateTime _resolvedActionDateTime(DateTime selectedDate, {DateTime? minimum}) {
    final now = DateTime.now();
    var value = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
    if (minimum != null && value.isBefore(minimum)) {
      value = minimum;
    }
    return value;
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _formatDateLabel(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd/$mm/${value.year}';
  }

  String _formatTimeLabel(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _confirmCloseManualEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Torna ad oggi?'),
        content: const Text(
          'Stai per uscire dalla modalità di timbratura manuale.\n\n'
          'Se vuoi modificare una timbratura di un giorno passato, '
          'dovrai fare una nuova richiesta di timbratura manuale per quel giorno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Torna ad oggi'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _dismissedManualEntryDates.add(_effectiveSelectedDate);
      });
      widget.onSelectedDateChanged?.call(_normalizeDate(DateTime.now()));
    }
  }

  void _syncManualDatesFromSelectedDate() {
    final selectedDate = _effectiveSelectedDate;
    final today = _normalizeDate(DateTime.now());
    if (_isSameDay(selectedDate, today)) {
      _manualSelectedDates = const <DateTime>[];
      return;
    }
    _manualSelectedDates = <DateTime>[selectedDate];
  }

  Future<void> _pickManualTime({required bool isClockIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isClockIn ? _manualClockInTime : _manualClockOutTime,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isClockIn) {
        _manualClockInTime = picked;
      } else {
        _manualClockOutTime = picked;
      }
    });
  }

  Future<void> _addManualDate(List<ClockingRecordEntity> records) async {
    final localization = AppLocalizations.of(context)!;
    final vacationDates = records
        .where((record) => record.isVacation)
        .map((record) => _normalizeDate(record.date))
        .toSet();
    final today = _normalizeDate(DateTime.now());
    final initialPickerDate = _resolveManualPickerInitialDate(
      vacationDates: vacationDates,
      today: today,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      selectableDayPredicate: (day) {
        final normalized = _normalizeDate(day);
        if (_isSameDay(normalized, today)) {
          return false;
        }
        if (vacationDates.contains(normalized)) {
          return false;
        }
        if (_manualSelectedDates.any((date) => _isSameDay(date, normalized))) {
          return false;
        }
        return true;
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    final normalized = _normalizeDate(picked);
    if (_isSameDay(normalized, today)) {
      AppSnackBar.showWarning(context, localization.manualClockingTodayLiveOnly);
      return;
    }
    if (vacationDates.contains(normalized)) {
      AppSnackBar.showWarning(context, localization.selectedDayMarkedAsVacation);
      return;
    }
    if (_manualSelectedDates.any((date) => _isSameDay(date, normalized))) {
      return;
    }
    setState(() {
      _manualSelectedDates = <DateTime>[..._manualSelectedDates, normalized]
        ..sort();
    });
  }

  void _removeManualDate(DateTime value) {
    if (_manualSelectedDates.length == 1) {
      return;
    }
    setState(() {
      _manualSelectedDates = _manualSelectedDates
          .where((date) => !_isSameDay(date, value))
          .toList();
    });
  }

  DateTime _resolveManualPickerInitialDate({
    required Set<DateTime> vacationDates,
    required DateTime today,
  }) {
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2100);

    bool isSelectable(DateTime date) {
      final normalized = _normalizeDate(date);
      if (_isSameDay(normalized, today)) {
        return false;
      }
      if (vacationDates.contains(normalized)) {
        return false;
      }
      if (_manualSelectedDates.any((value) => _isSameDay(value, normalized))) {
        return false;
      }
      return true;
    }

    final preferredDates = <DateTime>[_effectiveSelectedDate, ..._manualSelectedDates];
    for (final candidate in preferredDates) {
      if (candidate.isBefore(firstDate) || candidate.isAfter(lastDate)) {
        continue;
      }
      if (isSelectable(candidate)) {
        return candidate;
      }
    }

    for (var offset = 1; offset <= 3650; offset++) {
      final backward = _effectiveSelectedDate.subtract(Duration(days: offset));
      if (!backward.isBefore(firstDate) && isSelectable(backward)) {
        return backward;
      }
      final forward = _effectiveSelectedDate.add(Duration(days: offset));
      if (!forward.isAfter(lastDate) && isSelectable(forward)) {
        return forward;
      }
    }

    return today.subtract(const Duration(days: 1));
  }

  int _timeOfDayToMinutes(TimeOfDay value) {
    return (value.hour * 60) + value.minute;
  }
}

class _ClockingTeamSelector extends StatefulWidget {
  const _ClockingTeamSelector({
    required this.isCompact,
    required this.teams,
    required this.selectedTeamId,
    required this.onChanged,
  });

  final bool isCompact;
  final List<TeamEntity> teams;
  final String? selectedTeamId;
  final ValueChanged<String?> onChanged;

  @override
  State<_ClockingTeamSelector> createState() => _ClockingTeamSelectorState();
}

class _ClockingTeamSelectorState extends State<_ClockingTeamSelector> {
  static const double _kDropdownListMaxHeight = 248;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<TeamEntity> get _filteredTeams {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.teams.where((team) => team.id != null).toList();
    }
    return widget.teams.where((team) {
      if (team.id == null) {
        return false;
      }
      final name = team.name.toLowerCase();
      final description = team.description.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  bool get _showNoTeamOption {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return 'team'.contains(query);
  }

  TeamEntity? get _selectedTeam {
    if (widget.selectedTeamId == null) {
      return null;
    }
    for (final team in widget.teams) {
      if (team.id == widget.selectedTeamId) {
        return team;
      }
    }
    return null;
  }

  String get _title => _selectedTeam?.name ?? 'Team';

  String get _subtitle => _selectedTeam == null
      ? 'Nessun team selezionato'
      : 'Apri per cambiare team o cercarne uno';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ClockingTeamSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTeamId != widget.selectedTeamId) {
      _searchController.clear();
    }
  }

  void _selectTeam(String? teamId, VoidCallback close) {
    widget.onChanged(teamId);
    setState(() => _searchController.clear());
    close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(maxWidth: widget.isCompact ? 320 : 380),
      decoration: BoxDecoration(
        color: theme.colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnchoredDropdownOverlay(
          triggerBuilder: (context, isOpen, toggle) => _ClockingDropdownTrigger(
            title: _title,
            subtitle: _subtitle,
            isOpen: isOpen,
            onTap: toggle,
          ),
          overlayBuilder: (context, width, maxHeight, close) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cerca team...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: _kDropdownListMaxHeight,
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: _filteredTeams.length > 4,
                        child: ListView.separated(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount:
                              _filteredTeams.length +
                              (_showNoTeamOption ? 1 : 0) +
                              (_filteredTeams.isEmpty ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            if (_showNoTeamOption && index == 0) {
                              return _ClockingTeamOptionTile(
                                label: 'Team',
                                subtitle: 'Nessun team selezionato',
                                isSelected: widget.selectedTeamId == null,
                                onTap: () => _selectTeam(null, close),
                              );
                            }
                            final teamIndex = index - (_showNoTeamOption ? 1 : 0);
                            if (_filteredTeams.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                  color: colorScheme.surface,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 18,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Nessun team trovato',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final team = _filteredTeams[teamIndex];
                            return _ClockingTeamOptionTile(
                              label: team.name,
                              subtitle: team.description.trim().isNotEmpty
                                  ? team.description
                                  : 'Team disponibile per la timbratura',
                              isSelected: widget.selectedTeamId == team.id,
                              onTap: () => _selectTeam(team.id, close),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockingDropdownTrigger extends StatelessWidget {
  const _ClockingDropdownTrigger({
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOpen
                ? accent.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isOpen ? accent.withValues(alpha: 0.05) : colorScheme.surface,
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_rounded, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.descriptionColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockingTeamOptionTile extends StatelessWidget {
  const _ClockingTeamOptionTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primaryColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(Icons.group_work_rounded, size: 18, color: primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected) Icon(Icons.check_circle, color: primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ClockActionButton extends StatefulWidget {
  const _ClockActionButton({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isCompact,
    this.isDisabled = false,
  });

  final VoidCallback? onTap;
  final Color color;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isCompact;
  final bool isDisabled;

  @override
  State<_ClockActionButton> createState() => _ClockActionButtonState();
}

class _ClockActionButtonState extends State<_ClockActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final opacity = widget.isDisabled ? 0.4 : 1.0;

    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 14 : 20,
              vertical: widget.isCompact ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: widget.color.withValues(
                alpha: _isPressed
                    ? 0.22
                    : _isHovered
                        ? 0.18
                        : 0.1 * opacity,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.35 * opacity),
                width: 1.5,
              ),
              boxShadow: _isHovered && !widget.isDisabled
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15 * opacity),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: widget.isCompact ? 24 : 30,
                  color: widget.color.withValues(alpha: opacity),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: widget.color.withValues(alpha: opacity),
                  fontWeight: FontWeight.w700,
                  fontSize: widget.isCompact ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: widget.isCompact ? 120 : 150,
                child: Text(
                  widget.subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: widget.color.withValues(
                      alpha: widget.isDisabled ? 0.45 : 0.75,
                    ),
                    fontSize: widget.isCompact ? 10 : 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ), // AnimatedScale
      ),
    );
  }
}
