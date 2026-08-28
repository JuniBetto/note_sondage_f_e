import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/realtime/clocking_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_text_size.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/shift_absence_status.dart';
import 'package:note_sondage/feature/shift/ui/shift_assignment_access_policy.dart';
import 'package:note_sondage/feature/shift/ui/shift_density_scope.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_text_size_cubit.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_text_size_toggle.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_assignment_day_visibility.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_archived_assignments_list.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_loading_overlay.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_planner_dialog.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview_page.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_profile_manager.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_team_report_dialog.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_entries_sheet.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/app_confirmation_dialog.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:uuid/uuid.dart';

/// Mobile widget embedded inside the clocking section (or standalone).
class ShiftMobileWidget extends StatefulWidget {
  const ShiftMobileWidget({super.key});

  @override
  State<ShiftMobileWidget> createState() => _ShiftMobileWidgetState();
}

class _ShiftMobileWidgetState extends State<ShiftMobileWidget> {
  final GlobalKey _archiveToggleKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final TeamBloc _teamBloc = GetIt.instance<TeamBloc>();
  final TeamMemberBloc _teamMemberBloc = GetIt.instance<TeamMemberBloc>();
  final RoleUseCase _roleUseCase = GetIt.instance<RoleUseCase>();
  final ClockingUseCase _clockingUseCase = GetIt.instance<ClockingUseCase>();
  final ShiftRepository _shiftRepository = GetIt.instance<ShiftRepository>();
  final UserArchiveService _archiveService =
      GetIt.instance<UserArchiveService>();
  // Lets the user shrink/grow all text in this mobile layout to fit more
  // content on screen (see ShiftTextSizeToggle in the toolbar row below).
  final ShiftTextSizeCubit _shiftTextSizeCubit =
      GetIt.instance<ShiftTextSizeCubit>();
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  DateTime _focusedMonth = DateTime.now();
  List<ShiftAssignmentEntity> _assignments = [];
  List<ShiftProfileEntity> _profiles = [];
  List<TeamEntity> _teams = [];
  final Map<String, List<TeamMemberforView>> _teamMembersByTeamId = {};
  final Map<String, List<RoleEntity>> _rolesByTeamId = {};
  final Set<String> _loadingTeamMemberIds = <String>{};
  final Set<String> _loadingTeamRoleIds = <String>{};
  Map<String, ShiftAbsenceStatus> _absenceStatusesByKey = const {};
  Set<String> _archivedAssignmentIds = <String>{};
  bool _showArchivedOnly = false;
  bool _autoPlannerPreviewLoading = false;
  bool _tutorialScheduled = false;
  String? _selectedCalendarTeamId;

  String get _currentUid => GetIt.instance<AuthBloc>().state.user.uid;
  String get _currentEmail =>
      GetIt.instance<AuthBloc>().state.user.email.trim().toLowerCase();

  List<TeamEntityForView> get _manageableTeams {
    return _teams
        .where((team) => team.id != null && _canManageTeam(team))
        .map(
          (team) => TeamEntityForView(
            team: team,
            members: _teamMembersByTeamId[team.id!] ?? const [],
          ),
        )
        .toList();
  }

  bool get _canManageAnyTeam => _manageableTeams.isNotEmpty;

  TeamEntityForView? _calendarTeamById(String? teamId) {
    final normalizedTeamId = teamId?.trim();
    if (normalizedTeamId == null || normalizedTeamId.isEmpty) {
      return null;
    }

    final manageableTeam = _manageableTeams
        .where((team) => team.team.id == normalizedTeamId)
        .firstOrNull;
    if (manageableTeam != null) {
      return manageableTeam;
    }

    final rawTeam = _teams
        .where((team) => team.id == normalizedTeamId)
        .firstOrNull;
    if (rawTeam == null) {
      return null;
    }

    return TeamEntityForView(
      team: rawTeam,
      members: _teamMembersByTeamId[normalizedTeamId] ?? const [],
    );
  }

  TeamEntityForView? get _selectedCalendarTeam {
    return _calendarTeamById(_selectedCalendarTeamId);
  }

  List<ShiftAssignmentEntity> _filterAssignmentsForSelectedCalendarTeam(
    List<ShiftAssignmentEntity> assignments,
  ) {
    final availableTeamIds = _teams
        .map((team) => team.id?.trim())
        .whereType<String>()
        .where((teamId) => teamId.isNotEmpty)
        .toSet();
    final visibleAssignments = assignments
        .where(
          (assignment) =>
              ShiftAssignmentAccessPolicy.isVisibleWithAvailableTeams(
                assignment,
                availableTeamIds: availableTeamIds,
              ),
        )
        .toList();
    final selectedTeamId = _selectedCalendarTeamId;
    if (selectedTeamId == null || selectedTeamId.isEmpty) {
      return visibleAssignments
          .where((assignment) => assignment.userId == _currentUid)
          .toList();
    }
    return visibleAssignments
        .where((assignment) => assignment.teamId == selectedTeamId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadAssignments();
    unawaited(_loadShiftAbsenceStatuses());
    final teamState = _teamBloc.state;
    if (teamState is TeamsLoaded) {
      _teams = teamState.teams;
      _ensureTeamAccessContextLoaded(teamState.teams);
    }
    if (teamState is! TeamLoading) {
      _teamBloc.add(LoadTeamsEvent());
    }
    unawaited(_loadArchivedAssignmentsSafely());
    _realtimeSubscription = GetIt.instance<RealtimeNotificationService>().stream
        .listen(_handleRealtimeNotification);
    // Se arrivando sulla pagina c'è già un intent pendente (es. tap su
    // notifica allarme mentre si era già sulla pagina shift), consumalo
    // al primo frame disponibile dopo che lo stato è già ShiftAssignmentsLoaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final shiftState = context.read<ShiftBloc>().state;
        if (shiftState is ShiftAssignmentsLoaded) {
          _tryConsumeShiftOpenIntent(context);
        }
      } catch (error, stack) {
        debugPrint(
          '[ShiftMobileWidget] Failed while consuming pending shift intent: $error\n$stack',
        );
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _loadProfiles() {
    context.read<ShiftBloc>().add(LoadShiftProfilesEvent());
  }

  void _loadAssignments() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final selectedTeamId = _selectedCalendarTeamId?.trim();
    final visibleTeamIds = selectedTeamId == null || selectedTeamId.isEmpty
        ? const <String>[]
        : <String>[selectedTeamId];
    final selectedMembers = selectedTeamId == null || selectedTeamId.isEmpty
        ? const <TeamMemberforView>[]
        : (_teamMembersByTeamId[selectedTeamId] ??
              _selectedCalendarTeam?.members ??
              const <TeamMemberforView>[]);
    final visibleUserIds = selectedMembers
        .map((member) => member.teamMember.userId ?? '')
        .where((userId) => userId.isNotEmpty && userId != _currentUid)
        .toSet()
        .toList();
    context.read<ShiftBloc>().add(
      LoadShiftAssignmentsEvent(
        from: first,
        to: last,
        visibleTeamIds: visibleTeamIds.isEmpty ? null : visibleTeamIds,
        visibleUserIds: visibleUserIds.isEmpty ? null : visibleUserIds,
      ),
    );
  }

  Future<void> _loadShiftAbsenceStatuses() async {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final selectedTeamId = _selectedCalendarTeamId?.trim();
    try {
      final records = selectedTeamId == null || selectedTeamId.isEmpty
          ? await _clockingUseCase.getAllRecords()
          : await _clockingUseCase.getRecordsByTeamId(selectedTeamId);
      if (!mounted) {
        return;
      }
      setState(() {
        _absenceStatusesByKey = buildShiftAbsenceIndex(
          records,
          from: first,
          to: last,
          teamId: selectedTeamId,
          currentUserId: selectedTeamId == null || selectedTeamId.isEmpty
              ? _currentUid
              : null,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _absenceStatusesByKey = const {};
      });
    }
  }

  Map<String, ShiftAbsenceStatus> _absenceStatusesForDate(DateTime date) {
    return shiftAbsenceStatusesByUserForDate(_absenceStatusesByKey, date);
  }

  void _upsertAssignment(ShiftAssignmentEntity assignment) {
    final next = <ShiftAssignmentEntity>[
      ..._assignments.where((item) => item.id != assignment.id),
      assignment,
    ]..sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
    setState(() => _assignments = next);
  }

  void _removeAssignments(Iterable<String> assignmentIds) {
    final ids = assignmentIds.toSet();
    setState(() {
      _assignments = _assignments
          .where((assignment) => !ids.contains(assignment.id))
          .toList();
      _archivedAssignmentIds = _archivedAssignmentIds
          .where((id) => !ids.contains(id))
          .toSet();
    });
  }

  void _applyOptimisticAutoPlanAssignments({
    required String teamId,
    required DateTime from,
    required DateTime to,
    required List<ShiftAssignmentEntity> assignments,
  }) {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      return;
    }

    final rangeStart = DateTime(from.year, from.month, from.day);
    final rangeEnd = DateTime(to.year, to.month, to.day);

    bool isInsideRange(ShiftAssignmentEntity assignment) {
      final date = DateTime(
        assignment.shiftDate.year,
        assignment.shiftDate.month,
        assignment.shiftDate.day,
      );
      return !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
    }

    final replacementAssignments = assignments
        .where((assignment) => assignment.teamId?.trim() == normalizedTeamId)
        .where(isInsideRange)
        .toList(growable: false);

    final nextAssignments =
        _assignments
            .where(
              (assignment) =>
                  assignment.teamId?.trim() != normalizedTeamId ||
                  !isInsideRange(assignment),
            )
            .toList(growable: true)
          ..addAll(replacementAssignments)
          ..sort((left, right) {
            final byDate = left.shiftDate.compareTo(right.shiftDate);
            if (byDate != 0) {
              return byDate;
            }
            final byHour = left.startTime.hour.compareTo(right.startTime.hour);
            if (byHour != 0) {
              return byHour;
            }
            return left.startTime.minute.compareTo(right.startTime.minute);
          });

    setState(() => _assignments = nextAssignments);
  }

  void _upsertProfile(ShiftProfileEntity profile) {
    final next = <ShiftProfileEntity>[
      ..._profiles.where((item) => item.id != profile.id),
      profile,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() => _profiles = next);
  }

  void _removeProfile(String profileId) {
    setState(() {
      _profiles = _profiles
          .where((profile) => profile.id != profileId)
          .toList();
    });
  }

  Future<void> _loadArchivedAssignments() async {
    final archived = await _archiveService.loadArchivedIds(
      userId: _currentUid,
      bucket: ArchiveBuckets.shiftAssignments,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _archivedAssignmentIds = archived;
    });
  }

  Future<void> _loadArchivedAssignmentsSafely() async {
    try {
      await _loadArchivedAssignments();
    } catch (error, stack) {
      debugPrint(
        '[ShiftMobileWidget] Unable to load archived assignments: $error\n$stack',
      );
    }
  }

  Future<void> _setAssignmentArchived(
    ShiftAssignmentEntity assignment,
    bool archived,
  ) async {
    await _archiveService.setArchived(
      userId: _currentUid,
      bucket: ArchiveBuckets.shiftAssignments,
      itemId: assignment.id,
      archived: archived,
    );
    await _loadArchivedAssignments();
  }

  void _onMonthChanged(DateTime month) {
    setState(() => _focusedMonth = month);
    _loadAssignments();
  }

  void _ensureTeamAccessContextLoaded(List<TeamEntity> teams) {
    for (final team in teams) {
      final teamId = team.id;
      if (teamId == null) continue;
      if (!_teamMembersByTeamId.containsKey(teamId) &&
          _loadingTeamMemberIds.add(teamId)) {
        _teamMemberBloc.add(LoadTeamMembersByTeamIdEvent(teamId));
      }
      if (!_rolesByTeamId.containsKey(teamId) &&
          _loadingTeamRoleIds.add(teamId)) {
        _loadRolesForTeam(teamId);
      }
    }
  }

  Future<void> _loadRolesForTeam(String teamId) async {
    try {
      final roles = await _roleUseCase.getAllRolesByTeamId(teamId);
      if (!mounted) return;
      setState(() {
        _rolesByTeamId[teamId] = roles;
      });
    } catch (_) {
      // Keep the UI conservative: if roles cannot be loaded we do not grant
      // extra public-shift permissions beyond what we can prove locally.
    } finally {
      _loadingTeamRoleIds.remove(teamId);
    }
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
    if (!mounted) {
      return;
    }
    // The websocket push is best-effort: if this device was briefly
    // disconnected, any decision notification sent while offline (e.g. a
    // vacation/permission/sick request approved for the current user) is
    // lost for good. Resync everything on (re)connect so a missed event
    // still surfaces within seconds instead of requiring a manual reload.
    if (notification.eventType == 'SYSTEM_CONNECTED') {
      _loadAssignments();
      unawaited(_loadShiftAbsenceStatuses());
      return;
    }
    final shiftDecision = GetIt.instance<ShiftRealtimeCoordinator>()
        .resolveDecision(notification, currentUserId: _currentUid);
    final clockingDecision = GetIt.instance<ClockingRealtimeCoordinator>()
        .resolveDecision(
          notification,
          currentUserId: _currentUid,
          selectedTeamId: _selectedCalendarTeamId,
        );
    if (shiftDecision.refreshCalendar) {
      _loadAssignments();
    }
    if (shiftDecision.refreshCalendar || clockingDecision.refreshClocking) {
      unawaited(_loadShiftAbsenceStatuses());
    }
  }

  /// Consumes any pending deep-link intent queued by [ShiftOpenIntentController]
  /// (e.g. when the user tapped a push notification). Must be called after
  /// assignments have been loaded so we can look up the entity by ID.
  void _tryConsumeShiftOpenIntent(BuildContext context) {
    final intentController = GetIt.instance<ShiftOpenIntentController>();
    final intent = intentController.pendingIntent;
    if (intent == null) return;
    ShiftAssignmentEntity? existing;
    if (intent.assignmentId != null) {
      existing = _assignments
          .where((a) => a.id == intent.assignmentId)
          .firstOrNull;
    }

    final date = intent.shiftDate ?? existing?.shiftDate;
    if (date == null) {
      return;
    }

    final normalizedIntentTeamId = intent.teamId?.trim();
    final shouldChangeTeam =
        normalizedIntentTeamId != null &&
        normalizedIntentTeamId.isNotEmpty &&
        normalizedIntentTeamId != _selectedCalendarTeamId?.trim();
    final shouldChangeMonth =
        date.year != _focusedMonth.year || date.month != _focusedMonth.month;
    if (shouldChangeTeam || shouldChangeMonth) {
      setState(() {
        if (shouldChangeTeam) {
          _selectedCalendarTeamId = normalizedIntentTeamId;
        }
        if (shouldChangeMonth) {
          _focusedMonth = date;
        }
      });
      _loadAssignments();
      unawaited(_loadShiftAbsenceStatuses());
      return;
    }

    intentController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      var resolvedAssignment = existing;
      if (resolvedAssignment == null && intent.assignmentId != null) {
        resolvedAssignment = _assignments
            .where((a) => a.id == intent.assignmentId)
            .firstOrNull;
      }
      // Fallback: match by date if no assignmentId or not found
      final dayMatches = _assignments
          .where((assignment) => isAssignmentVisibleOnDate(assignment, date))
          .where(
            (assignment) =>
                normalizedIntentTeamId == null ||
                normalizedIntentTeamId.isEmpty ||
                assignment.teamId?.trim() == normalizedIntentTeamId,
          )
          .toList();
      final focusedUserMatches =
          intent.targetUserId == null || intent.targetUserId!.trim().isEmpty
          ? dayMatches
          : dayMatches
                .where(
                  (assignment) =>
                      assignment.userId.trim() == intent.targetUserId!.trim(),
                )
                .toList();
      if (resolvedAssignment == null) {
        if (intent.openDayEntriesWhenAssignmentMissing) {
          resolvedAssignment = null;
        } else if (focusedUserMatches.length == 1) {
          resolvedAssignment = focusedUserMatches.first;
        } else if (dayMatches.length == 1) {
          resolvedAssignment = dayMatches.first;
        }
      }
      if (resolvedAssignment == null &&
          intent.openDayEntriesWhenAssignmentMissing &&
          dayMatches.isNotEmpty) {
        await _openDayEntriesForIntent(
          context,
          date,
          dayMatches,
          highlightedUserId: intent.targetUserId,
        );
        return;
      }
      if (resolvedAssignment == null &&
          !intent.openDialogWhenAssignmentMissing) {
        return;
      }
      if (resolvedAssignment != null && intent.autoReplaceFromWorkflow) {
        final replaced = await _tryAutoReplaceFromWorkflow(
          context,
          resolvedAssignment,
          intent.preferredUserIds,
        );
        if (replaced || !context.mounted) {
          return;
        }
      }
      await _openDialogForAssignment(
        context,
        date,
        existing: resolvedAssignment,
        suggestedUserIds: intent.preferredUserIds,
      );
    });
  }

  Future<void> _openDayEntriesForIntent(
    BuildContext context,
    DateTime date,
    List<ShiftAssignmentEntity> assignments, {
    String? highlightedUserId,
  }) async {
    final shiftBloc = context.read<ShiftBloc>();
    final isPastDate = _isPastDate(date);
    final normalizedHighlightedUserId = highlightedUserId?.trim();
    final sortedAssignments = [...assignments]
      ..sort((a, b) {
        final leftHighlighted =
            normalizedHighlightedUserId != null &&
            normalizedHighlightedUserId.isNotEmpty &&
            a.userId.trim() == normalizedHighlightedUserId;
        final rightHighlighted =
            normalizedHighlightedUserId != null &&
            normalizedHighlightedUserId.isNotEmpty &&
            b.userId.trim() == normalizedHighlightedUserId;
        if (leftHighlighted != rightHighlighted) {
          return leftHighlighted ? -1 : 1;
        }
        final byTime = a.startTime.hour * 60 + a.startTime.minute;
        final otherTime = b.startTime.hour * 60 + b.startTime.minute;
        return byTime.compareTo(otherTime);
      });
    final action = await showShiftDayEntriesSheet(
      context: context,
      date: date,
      assignments: sortedAssignments,
      absenceStatuses: _absenceStatusesForDate(date).values.toList(),
      canCreate: !isPastDate,
      syncingAssignmentIds: shiftBloc.syncingAssignmentIds,
      highlightedUserIds:
          normalizedHighlightedUserId == null ||
              normalizedHighlightedUserId.isEmpty
          ? const <String>{}
          : <String>{normalizedHighlightedUserId},
    );
    if (!context.mounted || action == null) return;

    switch (action.type) {
      case ShiftDayEntriesActionType.createNew:
        if (isPastDate) {
          AppSnackBar.showWarning(
            context,
            _isItalian(context)
                ? 'Non puoi creare nuovi turni in una data precedente a oggi.'
                : 'You cannot create new shifts on a date before today.',
          );
          return;
        }
        await _openDialogForAssignment(context, date);
        break;
      case ShiftDayEntriesActionType.openExisting:
        await _openDialogForAssignment(
          context,
          date,
          existing: action.assignment,
        );
        break;
    }
  }

  bool _canManageAssignment(ShiftAssignmentEntity assignment) {
    return ShiftAssignmentAccessPolicy.canManageAssignment(
      assignment,
      currentUserId: _currentUid,
      manageableTeamIds: _manageableTeams
          .map((team) => team.team.id)
          .whereType<String>(),
    );
  }

  bool _canRequestAssignmentChange(ShiftAssignmentEntity assignment) {
    final canManageAssignment = _canManageAssignment(assignment);
    return ShiftAssignmentAccessPolicy.canRequestAssignmentChange(
      assignment,
      currentUserId: _currentUid,
      canManageAssignment: canManageAssignment,
    );
  }

  bool _canRequestAssignmentSwap(ShiftAssignmentEntity assignment) {
    return assignment.isPublic &&
        ShiftAssignmentAccessPolicy.hasTeamScope(assignment) &&
        assignment.userId == _currentUid;
  }

  bool _canEditApprovedAssignment(ShiftAssignmentEntity assignment) {
    final canManageAssignment = _canManageAssignment(assignment);
    return ShiftAssignmentAccessPolicy.canEditApprovedAssignment(
      assignment,
      currentUserId: _currentUid,
      canManageAssignment: canManageAssignment,
    );
  }

  bool _canManageTeam(TeamEntity team) {
    final teamId = team.id;
    if (teamId == null) return false;
    if (team.createdByUserId == _currentUid) return true;

    final currentMember = _findCurrentTeamMember(teamId);
    final roleCode = _normalizeRoleCode(currentMember?.teamMember.roleId);
    if (roleCode == 'OWNER' || roleCode == 'ADMIN') {
      return true;
    }

    final permissions = _normalizePermissions(
      roleCode,
      _findRoleByCode(teamId, roleCode)?.permissions,
    );
    return permissions.contains('ADMIN') || permissions.contains('MANAGE');
  }

  /// The bulk "delete all shifts for this day" action is only offered when
  /// a specific, manageable team is selected — not in the personal "my
  /// shifts across every team" aggregate view (no single team to act on).
  bool get _canDeleteSelectedCalendarDay {
    final team = _selectedCalendarTeam?.team;
    return team != null && _canManageTeam(team);
  }

  Future<void> _confirmAndDeleteAllShiftsForDay(
    BuildContext context,
    DateTime date,
    List<ShiftAssignmentEntity> dayAssignments,
  ) async {
    if (dayAssignments.isEmpty) {
      return;
    }
    final localization = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: localization.deleteAllShiftsForDayTitle,
      message: localization.deleteAllShiftsForDayMessage(
        dayAssignments.length,
      ),
      confirmLabel: localization.deleteAction,
      destructive: true,
    );
    if (!context.mounted || !confirmed) {
      return;
    }
    final shiftBloc = context.read<ShiftBloc>();
    for (final assignment in dayAssignments) {
      shiftBloc.add(DeleteShiftAssignmentEvent(assignment.id));
    }
  }

  TeamMemberforView? _findCurrentTeamMember(String teamId) {
    final members = _teamMembersByTeamId[teamId];
    if (members == null || members.isEmpty) return null;

    for (final member in members) {
      final memberUserId = member.teamMember.userId?.trim();
      if (memberUserId != null &&
          memberUserId.isNotEmpty &&
          memberUserId == _currentUid) {
        return member;
      }
    }

    for (final member in members) {
      if (member.teamMember.userEmail.trim().toLowerCase() == _currentEmail) {
        return member;
      }
    }
    return null;
  }

  String _normalizeRoleCode(String? value) {
    return value?.trim().toUpperCase() ?? '';
  }

  RoleEntity? _findRoleByCode(String teamId, String roleCode) {
    final roles = _rolesByTeamId[teamId];
    if (roles == null || roles.isEmpty) return null;
    for (final role in roles) {
      if (_normalizeRoleCode(role.id) == roleCode) {
        return role;
      }
    }
    return null;
  }

  Set<String> _normalizePermissions(
    String roleCode,
    List<String>? permissions,
  ) {
    if (permissions == null || permissions.isEmpty) {
      return switch (roleCode) {
        'OWNER' => {'READ', 'UPDATE', 'ADMIN', 'DELETE', 'MANAGE'},
        'ADMIN' => {'READ', 'UPDATE', 'ADMIN', 'DELETE'},
        _ => {'READ'},
      };
    }

    return permissions
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> _openDialogForAssignment(
    BuildContext context,
    DateTime date, {
    ShiftAssignmentEntity? existing,
    List<String> suggestedUserIds = const <String>[],
  }) async {
    final shiftBloc = context.read<ShiftBloc>();
    final result = await showShiftDayDialog(
      context: context,
      date: date,
      profiles: _profiles,
      allTeams: _teams,
      existing: existing,
      initialTeamId: existing == null ? _selectedCalendarTeamId : null,
      absenceStatusesByUserId: _absenceStatusesForDate(date),
      canManagePublicShifts: existing == null
          ? _canManageAnyTeam
          : _canManageAssignment(existing),
      canRequestPublicShiftChanges: existing != null
          ? _canRequestAssignmentChange(existing)
          : false,
      canRequestAssignmentSwap: existing != null
          ? _canRequestAssignmentSwap(existing)
          : false,
      hasPendingPublicShiftChangeRequest: existing != null
          ? _hasPendingAssignmentChangeRequest(existing)
          : false,
      canEditApprovedPublicShift: existing != null
          ? _canEditApprovedAssignment(existing)
          : false,
      ownerTeams: _manageableTeams,
      suggestedUserIds: suggestedUserIds,
      onOpenLinkedConversation:
          existing != null &&
              existing.workflowContext.resolvedSourceConversationId != null
          ? () => _openLinkedConversationForAssignment(existing)
          : null,
    );
    if (result == null) return;
    if (!context.mounted) return;

    if (result.requestedChange && existing != null) {
      await _requestAssignmentChange(context, existing, result);
      return;
    }

    if (result.requestedSwap && existing != null) {
      await _requestAssignmentSwap(context, existing, result);
      return;
    }

    if (result.archived && existing != null) {
      await _setAssignmentArchived(existing, true);
      return;
    }

    if (result.deleted && existing != null) {
      final localization = AppLocalizations.of(context)!;
      final confirmed = await showAppConfirmationDialog(
        context,
        title: localization.deleteShiftTitle,
        message: localization.deleteShiftMessage,
        confirmLabel: localization.deleteAction,
        destructive: true,
      );
      if (!context.mounted || !confirmed) return;

      shiftBloc.add(DeleteShiftAssignmentEvent(existing.id));
      return;
    }

    if (existing != null) {
      // ── public → privato: cancella tutti i turni degli altri membri ──────
      final wasPublic = existing.isPublic;
      final nowPrivate = !result.isPublic;
      if (wasPublic &&
          nowPrivate &&
          existing.teamId != null &&
          existing.teamShiftGroupId == null) {
        final toDelete = _relatedPublicAssignments(
          existing,
        ).where((assignment) => assignment.id != existing.id);
        for (final a in toDelete) {
          shiftBloc.add(DeleteShiftAssignmentEvent(a.id));
        }
      }

      // public → public: il backend aggiornerà TUTTE le righe del team in automatico
      shiftBloc.add(
        UpdateShiftAssignmentEvent(
          assignmentId: existing.id,
          profileId: result.profileId,
          startTime: result.startTime,
          endTime: result.endTime,
          overnight: result.overnight,
          note: result.note,
          alarmOffsets: result.alarmOffsets,
          isPublic: result.isPublic,
          teamId: result.isPublic ? result.teamId : null,
          teamShiftGroupId: existing.teamShiftGroupId,
          // Pass the new target only when the manager picked a different member.
          targetUserId: result.isPublic && result.targetUserIds.length == 1
              ? result.targetUserIds.first
              : null,
        ),
      );
      return;
    }

    await _createAssignments(context, shiftBloc, date, result);
  }

  void _openLinkedConversationForAssignment(ShiftAssignmentEntity assignment) {
    final teamId = assignment.workflowContext.resolvedTeamId;
    final conversationId =
        assignment.workflowContext.resolvedSourceConversationId;
    if (teamId == null ||
        teamId.isEmpty ||
        conversationId == null ||
        conversationId.isEmpty) {
      AppSnackBar.showWarning(
        context,
        _isItalian(context)
            ? 'Questo turno non ha una conversazione collegata apribile.'
            : 'This shift does not have a linked conversation to open.',
      );
      return;
    }

    final path = Uri(
      path: RouterPaths.sondageChatConversation,
      queryParameters: <String, String>{
        'teamId': teamId,
        'conversationId': conversationId,
        'focus': 'latest',
      },
    ).toString();
    context.go(path);
  }

  Future<bool> _tryAutoReplaceFromWorkflow(
    BuildContext context,
    ShiftAssignmentEntity existing,
    List<String> preferredUserIds,
  ) async {
    final preferred = preferredUserIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (preferred.isEmpty) {
      return false;
    }
    try {
      final result = await _shiftRepository.findReplacementCandidates(
        existing.id,
      );
      if (!context.mounted) {
        return false;
      }
      final candidate = result.candidates
          .where((item) => item.compatible)
          .where((item) => preferred.contains(item.userId.trim()))
          .firstOrNull;
      if (candidate == null) {
        AppSnackBar.showWarning(
          context,
          _isItalian(context)
              ? 'Nessun collega disponibile dal sondaggio e compatibile per questo turno. Apro il dettaglio per scegliere manualmente.'
              : 'No available survey respondent is compatible with this shift. Opening the detail so you can choose manually.',
        );
        return false;
      }

      context.read<ShiftBloc>().add(
        UpdateShiftAssignmentEvent(
          assignmentId: existing.id,
          profileId: existing.profileId,
          startTime: existing.startTime,
          endTime: existing.endTime,
          overnight: existing.overnight,
          note: existing.note,
          alarmOffsets: existing.alarmOffsets,
          isPublic: existing.isPublic,
          teamId: existing.teamId,
          teamShiftGroupId: existing.teamShiftGroupId,
          targetUserId: candidate.userId,
        ),
      );
      AppSnackBar.showSuccess(
        context,
        _isItalian(context)
            ? 'Sostituzione avviata con ${candidate.displayName}.'
            : 'Replacement started with ${candidate.displayName}.',
      );
      return true;
    } catch (error) {
      if (!context.mounted) {
        return true;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: _isItalian(context)
            ? 'Non siamo riusciti a sostituire automaticamente il turno.'
            : 'We could not replace the shift automatically.',
      );
      return true;
    }
  }

  Future<void> _requestAssignmentChange(
    BuildContext context,
    ShiftAssignmentEntity existing,
    ShiftDayDialogResult result,
  ) async {
    try {
      await _shiftRepository.requestAssignmentChange(
        existing.id,
        startTime: result.startTime,
        endTime: result.endTime,
        overnight: result.overnight,
        note: result.note,
      );
      if (!context.mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        'La richiesta di modifica turno e stata inviata.',
      );
      _loadAssignments();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback:
            'Non siamo riusciti a inviare la richiesta di modifica turno.',
      );
    }
  }

  Future<void> _requestAssignmentSwap(
    BuildContext context,
    ShiftAssignmentEntity existing,
    ShiftDayDialogResult result,
  ) async {
    final candidateUserId = result.swapCandidateUserId?.trim();
    if (candidateUserId == null || candidateUserId.isEmpty) {
      return;
    }
    try {
      await _shiftRepository.requestAssignmentSwap(
        existing.id,
        candidateUserId: candidateUserId,
        note: result.swapNote,
      );
      if (!context.mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        _isItalian(context)
            ? 'La richiesta di sostituzione turno e stata inviata.'
            : 'The shift swap request has been sent.',
      );
      _loadAssignments();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: _isItalian(context)
            ? 'Non siamo riusciti a inviare la richiesta di sostituzione turno.'
            : 'We could not send the shift swap request.',
      );
    }
  }

  List<ShiftAssignmentCreateRequestEntity> _buildCreateRequests(
    DateTime fallbackDate,
    ShiftDayDialogResult result,
  ) {
    final scheduledDates = result.scheduledDates.isEmpty
        ? <DateTime>[fallbackDate]
        : result.scheduledDates;
    final targetUserIds = result.targetUserIds.isEmpty
        ? const <String?>[null]
        : result.targetUserIds.cast<String?>();
    final uuid = const Uuid();
    final hasMemberSpecificPlans = result.memberAssignmentPlans.isNotEmpty;
    final requests = <ShiftAssignmentCreateRequestEntity>[];

    for (final scheduledDate in scheduledDates) {
      if (hasMemberSpecificPlans) {
        for (final plan in result.memberAssignmentPlans) {
          requests.add(
            ShiftAssignmentCreateRequestEntity(
              shiftDate: scheduledDate,
              profileId: plan.profileId ?? result.profileId,
              startTime: plan.profileId == null ? result.startTime : null,
              endTime: plan.profileId == null ? result.endTime : null,
              overnight: plan.profileId == null ? result.overnight : null,
              note: result.note,
              alarmOffsets: plan.profileId == null ? result.alarmOffsets : null,
              isPublic: result.isPublic,
              teamId: result.isPublic ? result.teamId : null,
              teamShiftGroupId: result.isPublic ? uuid.v4() : null,
              targetUserId: plan.targetUserId,
              targetUserName: _optimisticTargetUserName(plan.targetUserId),
              contextType: result.contextType,
              contextId: result.contextId,
              sourceType: result.sourceType,
              sourceId: result.sourceId,
              sourceMessageId: result.sourceMessageId,
            ),
          );
        }
        continue;
      }

      final sharedGroupId = result.isPublic ? uuid.v4() : null;
      for (final targetUserId in targetUserIds) {
        requests.add(
          ShiftAssignmentCreateRequestEntity(
            shiftDate: scheduledDate,
            profileId: result.profileId,
            startTime: result.startTime,
            endTime: result.endTime,
            overnight: result.overnight,
            note: result.note,
            alarmOffsets: result.alarmOffsets,
            isPublic: result.isPublic,
            teamId: result.isPublic ? result.teamId : null,
            teamShiftGroupId: sharedGroupId,
            targetUserId: targetUserId,
            targetUserName: _optimisticTargetUserName(targetUserId),
            contextType: result.contextType,
            contextId: result.contextId,
            sourceType: result.sourceType,
            sourceId: result.sourceId,
            sourceMessageId: result.sourceMessageId,
          ),
        );
      }
    }

    return requests;
  }

  String _bulkCreateSuccessMessage(BuildContext context, int createdCount) {
    final isItalian = _isItalian(context);
    return isItalian
        ? 'Creati $createdCount turni con successo.'
        : 'Created $createdCount shifts successfully.';
  }

  Future<void> _createAssignments(
    BuildContext context,
    ShiftBloc shiftBloc,
    DateTime fallbackDate,
    ShiftDayDialogResult result,
  ) async {
    final requests = _buildCreateRequests(fallbackDate, result);
    if (requests.isEmpty) {
      return;
    }

    if (requests.length == 1) {
      final request = requests.single;
      shiftBloc.add(
        AssignShiftEvent(
          shiftDate: request.shiftDate,
          profileId: request.profileId,
          startTime: request.startTime,
          endTime: request.endTime,
          overnight: request.overnight,
          note: request.note,
          alarmOffsets: request.alarmOffsets,
          isPublic: request.isPublic,
          teamId: request.teamId,
          teamShiftGroupId: request.teamShiftGroupId,
          targetUserId: request.targetUserId,
        ),
      );
      return;
    }

    shiftBloc.add(AssignShiftBatchEvent(requests: requests));
  }

  String? _optimisticTargetUserName(String? userId) {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return null;
    }
    for (final members in _teamMembersByTeamId.values) {
      for (final member in members) {
        if (member.teamMember.userId?.trim() == normalizedUserId) {
          final label = _previewUserLabel(member).trim();
          if (label.isNotEmpty) {
            return label;
          }
        }
      }
    }
    return normalizedUserId == _currentUid ? _currentEmail : null;
  }

  bool _hasPendingAssignmentChangeRequest(ShiftAssignmentEntity assignment) {
    if (!ShiftAssignmentAccessPolicy.hasTeamScope(assignment)) {
      return false;
    }
    if (assignment.memberChangeRequestPending) {
      return true;
    }
    final state = context.read<NotificationCenterCubit>().state;
    return state.notifications.any((item) {
      if (item.eventType != 'SHIFT_CHANGE_REQUESTED') {
        return false;
      }
      if (state.dismissedNotificationIds.contains(item.notificationId) ||
          state.completedActionNotificationIds.contains(item.notificationId)) {
        return false;
      }
      return item.requestType == 'shift_change' &&
          item.requesterUserId == _currentUid &&
          item.metadata['assignmentId']?.trim() == assignment.id;
    });
  }

  Iterable<ShiftAssignmentEntity> _relatedPublicAssignments(
    ShiftAssignmentEntity existing,
  ) {
    final teamId = ShiftAssignmentAccessPolicy.normalizedTeamId(
      existing.teamId,
    );
    if (!existing.isPublic || teamId == null) {
      return [existing];
    }

    return _assignments.where(
      (assignment) =>
          assignment.isPublic &&
          ShiftAssignmentAccessPolicy.normalizedTeamId(assignment.teamId) ==
              teamId &&
          _isSameShiftDate(assignment.shiftDate, existing.shiftDate) &&
          (existing.teamShiftGroupId != null
              ? assignment.teamShiftGroupId == existing.teamShiftGroupId
              : _isSameShiftTime(assignment, existing) &&
                    assignment.overnight == existing.overnight &&
                    (assignment.profileId == existing.profileId ||
                        assignment.profileName == existing.profileName)),
    );
  }

  bool _isSameShiftDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _isSameShiftTime(
    ShiftAssignmentEntity left,
    ShiftAssignmentEntity right,
  ) {
    return left.startTime.hour == right.startTime.hour &&
        left.startTime.minute == right.startTime.minute &&
        left.endTime.hour == right.endTime.hour &&
        left.endTime.minute == right.endTime.minute;
  }

  Future<void> _onDayTap(
    BuildContext context,
    DateTime date,
    List<ShiftAssignmentEntity> assignments,
  ) async {
    final shiftBloc = context.read<ShiftBloc>();
    final isPastDate = _isPastDate(date);
    final sortedAssignments = [...assignments]
      ..sort((a, b) {
        final byTime = a.startTime.hour * 60 + a.startTime.minute;
        final otherTime = b.startTime.hour * 60 + b.startTime.minute;
        return byTime.compareTo(otherTime);
      });

    if (sortedAssignments.isEmpty) {
      if (isPastDate) {
        AppSnackBar.showWarning(
          context,
          _isItalian(context)
              ? 'Non puoi creare nuovi turni in una data precedente a oggi.'
              : 'You cannot create new shifts on a date before today.',
        );
        return;
      }
      await _openDialogForAssignment(context, date);
      return;
    }

    final action = await showShiftDayEntriesSheet(
      context: context,
      date: date,
      assignments: sortedAssignments,
      absenceStatuses: _absenceStatusesForDate(date).values.toList(),
      canCreate: !isPastDate,
      syncingAssignmentIds: shiftBloc.syncingAssignmentIds,
    );
    if (!context.mounted || action == null) return;

    switch (action.type) {
      case ShiftDayEntriesActionType.createNew:
        if (isPastDate) {
          AppSnackBar.showWarning(
            context,
            _isItalian(context)
                ? 'Non puoi creare nuovi turni in una data precedente a oggi.'
                : 'You cannot create new shifts on a date before today.',
          );
          return;
        }
        await _openDialogForAssignment(context, date);
        break;
      case ShiftDayEntriesActionType.openExisting:
        await _openDialogForAssignment(
          context,
          date,
          existing: action.assignment,
        );
        break;
    }
  }

  Future<void> _openProfilesSheet(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final shiftBloc = context.read<ShiftBloc>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colorScheme.bgNavbarSurface,
      builder: (sheetContext) => BlocProvider.value(
        value: shiftBloc,
        child: SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.74,
            minChildSize: 0.52,
            maxChildSize: 0.94,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.shiftProfile,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ShiftProfileManager(
                          profiles: _profiles,
                          syncingProfileIds: context
                              .read<ShiftBloc>()
                              .syncingProfileIds,
                          isOwner: _canManageAnyTeam,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final navButtonColor = colorScheme.bgNavbarbutton ?? colorScheme.primary;
    final foregroundAssignments = _filterAssignmentsForSelectedCalendarTeam(
      _assignments
          .where(
            (assignment) => !_archivedAssignmentIds.contains(assignment.id),
          )
          .toList(),
    );
    final archivedAssignments = _filterAssignmentsForSelectedCalendarTeam(
      _assignments
          .where((assignment) => _archivedAssignmentIds.contains(assignment.id))
          .toList(),
    );
    final calendarOrArchiveContent = _showArchivedOnly
        ? ShiftArchivedAssignmentsList(
            assignments: archivedAssignments,
            compact: false,
            onOpen: (assignment) {
              _openDialogForAssignment(
                context,
                assignment.shiftDate,
                existing: assignment,
              );
            },
            onRestore: (assignment) {
              _setAssignmentArchived(assignment, false);
            },
          )
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ShiftCalendarWidget(
              assignments: foregroundAssignments,
              absenceStatuses: _absenceStatusesByKey.values.toList(
                growable: false,
              ),
              syncingAssignmentIds: context
                  .read<ShiftBloc>()
                  .syncingAssignmentIds,
              focusedMonth: _focusedMonth,
              onMonthChanged: _onMonthChanged,
              onDayTap: (date, assignments) =>
                  _onDayTap(context, date, assignments),
              onDeleteDay: _canDeleteSelectedCalendarDay
                  ? (date, dayAssignments) => _confirmAndDeleteAllShiftsForDay(
                      context,
                      date,
                      dayAssignments,
                    )
                  : null,
            ),
          );

    AppTutorialController.registerTargets(
      tutorialId: 'mobile-shifts',
      keys: <GlobalKey>[_archiveToggleKey, _calendarKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-shifts',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_archiveToggleKey, _calendarKey],
      ),
    );
    _scheduleTutorial();

    return MultiBlocListener(
      listeners: [
        BlocListener<ShiftBloc, ShiftState>(
          listener: (context, state) {
            if (state is ShiftProfilesLoaded) {
              setState(() => _profiles = state.profiles);
            }
            if (state is ShiftProfileCreated) {
              _upsertProfile(state.profile);
            }
            if (state is ShiftProfileUpdated) {
              _upsertProfile(state.profile);
            }
            if (state is ShiftProfileDeleted) {
              _removeProfile(state.profileId);
            }
            if (state is ShiftAssignmentsLoaded) {
              setState(() => _assignments = state.assignments);
              // Open the specific shift if we arrived here via a notification tap
              _tryConsumeShiftOpenIntent(context);
            }
            if (state is ShiftAssigned) {
              final isSyncing = context
                  .read<ShiftBloc>()
                  .syncingAssignmentIds
                  .contains(state.assignment.id);
              if (!isSyncing &&
                  state.assignment.isPublic &&
                  state.assignment.teamShiftGroupId != null) {
                _loadAssignments();
              } else {
                _upsertAssignment(state.assignment);
              }
            }
            if (state is ShiftBatchAssigned) {
              AppSnackBar.showSuccess(
                context,
                _bulkCreateSuccessMessage(context, state.createdCount),
              );
            }
            if (state is ShiftAssignmentUpdated) {
              final isSyncing = context
                  .read<ShiftBloc>()
                  .syncingAssignmentIds
                  .contains(state.assignment.id);
              if (!isSyncing &&
                  state.assignment.isPublic &&
                  state.assignment.teamShiftGroupId != null) {
                _loadAssignments();
              } else {
                _upsertAssignment(state.assignment);
              }
            }
            if (state is ShiftAssignmentDeleted) {
              _removeAssignments(state.assignmentIds);
            }
            if (state is ShiftError) {
              AppSnackBar.showError(context, state.message);
            }
          },
        ),
        BlocListener<TeamBloc, TeamState>(
          bloc: _teamBloc,
          listener: (context, state) {
            if (state is TeamsLoaded) {
              setState(() {
                _teams = state.teams;
                final selectedTeamId = _selectedCalendarTeamId;
                if (selectedTeamId != null &&
                    !_teams.any((team) => team.id == selectedTeamId)) {
                  _selectedCalendarTeamId = null;
                }
              });
              _ensureTeamAccessContextLoaded(state.teams);
              _loadAssignments();
            }
          },
        ),
        BlocListener<TeamMemberBloc, TeamMemberState>(
          bloc: _teamMemberBloc,
          listener: (context, state) {
            if (state is TeamMembersLoaded) {
              final teamId =
                  state.teamId ??
                  (state.members.isNotEmpty
                      ? state.members.first.teamId
                      : null);
              if (teamId != null) {
                _loadingTeamMemberIds.remove(teamId);
                final shouldRefreshAssignments =
                    _selectedCalendarTeamId?.trim().isNotEmpty == true &&
                    teamId == _selectedCalendarTeamId?.trim();
                setState(() {
                  _teamMembersByTeamId[teamId] = state.members
                      .map((member) => TeamMemberforView(teamMember: member))
                      .toList();
                });
                if (shouldRefreshAssignments) {
                  _loadAssignments();
                }
              }
            }
            if (state is TeamMemberError) {
              if (state.teamId != null) {
                _loadingTeamMemberIds.remove(state.teamId);
              } else {
                _loadingTeamMemberIds.clear();
              }
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /* Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.descriptionColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.myShifts,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),*/
                    // const Spacer(),
                    const ShiftTextSizeToggle(),
                    const SizedBox(width: 6),
                    if (_canManageAnyTeam) ...[
                      IconButton.outlined(
                        tooltip: _isItalian(context)
                            ? 'Generazione automatica turni'
                            : 'Automatic shift planner',
                        onPressed: () => _openAutoPlanner(context),
                        icon: Icon(
                          Icons.auto_awesome_outlined,
                          size: 18,
                          color: colorScheme.textInvertedColor,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navButtonColor,
                          side: BorderSide(color: navButtonColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.outlined(
                        tooltip: loc.shiftTeamReportTooltip,
                        onPressed: () => _openTeamReport(context),
                        icon: Icon(
                          Icons.assessment_outlined,
                          size: 18,
                          color: colorScheme.textInvertedColor,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navButtonColor,
                          side: BorderSide(color: navButtonColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton.outlined(
                      tooltip: _isItalian(context)
                          ? 'Profili turno'
                          : 'Shift profiles',
                      onPressed: () => _openProfilesSheet(context),
                      icon: Icon(
                        Icons.palette_outlined,
                        color: colorScheme.textInvertedColor,
                        size: 18,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navButtonColor,
                        side: BorderSide(color: navButtonColor),
                      ),
                    ),
                    if (_canManageAnyTeam) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 16,
                        color: colorScheme.descriptionColor,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (_canManageAnyTeam && !_showArchivedOnly) ...[
                  ShiftCalendarTeamPicker(
                    teams: _manageableTeams,
                    selectedTeamId: _selectedCalendarTeamId,
                    onChanged: (value) {
                      setState(() {
                        _selectedCalendarTeamId = value;
                      });
                      _loadAssignments();
                      unawaited(_loadShiftAbsenceStatuses());
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Showcase(
                  key: _archiveToggleKey,
                  title: _isItalian(context)
                      ? 'Calendario e archivio'
                      : 'Calendar and archive',
                  description: _isItalian(context)
                      ? 'Usa questo selettore per passare dal calendario attivo all\'archivio dei turni nascosti.'
                      : 'Use this switcher to move between the active calendar and the archive of hidden shifts.',
                  child: ArchiveViewToggle(
                    showArchivedOnly: _showArchivedOnly,
                    primaryCount: foregroundAssignments.length,
                    archivedCount: archivedAssignments.length,
                    primaryLabel: 'Calendario',
                    archivedLabel: 'Archivio',
                    onChanged: (value) {
                      setState(() => _showArchivedOnly = value);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Showcase(
                    key: _calendarKey,
                    title: _showArchivedOnly
                        ? (_isItalian(context)
                              ? 'Archivio turni'
                              : 'Shift archive')
                        : (_isItalian(context)
                              ? 'Calendario turni'
                              : 'Shift calendar'),
                    description: _showArchivedOnly
                        ? (_isItalian(context)
                              ? 'Qui ritrovi i turni archiviati e puoi riaprirli quando servono.'
                              : 'This view shows archived shifts and lets you restore them when needed.')
                        : (_isItalian(context)
                              ? 'Tocca un giorno per creare o modificare i turni disponibili in quella data.'
                              : 'Tap a day to create or edit the shifts available on that date.'),
                    child: BlocBuilder<ShiftTextSizeCubit, ShiftTextSize>(
                      bloc: _shiftTextSizeCubit,
                      builder: (context, textSize) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(textSize.scaleFactor),
                          ),
                          child: ShiftDensityScope(
                            scale: textSize.scaleFactor,
                            child: calendarOrArchiveContent,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_autoPlannerPreviewLoading)
            const Positioned.fill(
              child: ShiftAutoPlanLoadingOverlay(compact: true),
            ),
        ],
      ),
    );
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      try {
        await AppTutorialController.showIfNeeded(
          context: context,
          tutorialId: 'mobile-shifts',
          userId: context.read<AuthBloc>().state.user.uid,
          keys: <GlobalKey>[_archiveToggleKey, _calendarKey],
        );
      } catch (error, stack) {
        debugPrint(
          '[ShiftMobileWidget] Tutorial skipped after error: $error\n$stack',
        );
      }
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.isBefore(today);
  }

  Future<void> _openTeamReport(BuildContext context) async {
    await ShiftTeamReportDialog.show(
      context,
      teams: _manageableTeams,
      compact: true,
    );
  }

  Future<void> _openAutoPlanner(BuildContext context) async {
    final isItalian = _isItalian(context);
    final request = await ShiftAutoPlannerDialog.show(
      context,
      teams: _manageableTeams,
      profiles: _profiles,
      initialTeamId: _selectedCalendarTeamId,
      initialFrom: DateTime(_focusedMonth.year, _focusedMonth.month, 1),
      initialTo: DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0),
      compact: true,
    );
    if (request == null || !mounted) {
      return;
    }

    try {
      setState(() => _autoPlannerPreviewLoading = true);
      final preview = await _shiftRepository.previewAutoPlan(request);
      if (mounted) {
        setState(() => _autoPlannerPreviewLoading = false);
      }
      if (!mounted || !context.mounted) {
        return;
      }
      final teamName = _manageableTeams
          .where((team) => team.team.id == request.teamId)
          .map((team) => team.team.name.trim())
          .where((name) => name.isNotEmpty)
          .firstOrNull;
      final teamMembers = _manageableTeams
          .where((team) => team.team.id == request.teamId)
          .map((team) => team.members)
          .firstOrNull;
      final confirmation = await ShiftAutoPlanPreviewPage.show(
        context,
        request: request,
        preview: preview,
        availableProfiles: _profiles,
        availableTeamMembers: teamMembers ?? const <TeamMemberforView>[],
        onRecalculate: (snapshotToken, draftAssignments) => _shiftRepository
            .recalculateAutoPlanPreview(snapshotToken, draftAssignments),
        onConfirm: (snapshotToken) =>
            _shiftRepository.confirmAutoPlan(snapshotToken),
        teamName: teamName,
        userLabelsById: _buildPreviewUserLabels(teamMembers),
        compact: true,
      );
      if (confirmation == null || !mounted || !context.mounted) {
        return;
      }
      final result = confirmation.result;
      final focusedMonth = DateTime(request.from.year, request.from.month, 1);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _selectedCalendarTeamId = request.teamId;
        _focusedMonth = focusedMonth;
      });
      _applyOptimisticAutoPlanAssignments(
        teamId: request.teamId,
        from: request.from,
        to: request.to,
        assignments: confirmation.assignments,
      );
      _loadAssignments();
      unawaited(_loadShiftAbsenceStatuses());

      if (result.createdAssignmentsCount > 0) {
        AppSnackBar.showSuccess(
          context,
          isItalian
              ? 'Creati ${result.createdAssignmentsCount} turni automatici.'
              : 'Created ${result.createdAssignmentsCount} automatic shifts.',
        );
      } else if (result.uncoveredSlotsCount == 0) {
        final alreadyCoveredMessage = isItalian
            ? result.preservedAssignmentsCount > 0
                  ? 'Nessun nuovo turno creato: i turni esistenti coprono gia l\'intervallo selezionato.'
                  : 'Nessun nuovo turno da creare per l\'intervallo selezionato.'
            : result.preservedAssignmentsCount > 0
            ? 'No new shifts were created: existing assignments already cover the selected range.'
            : 'No new shifts were needed for the selected range.';
        AppSnackBar.showSuccess(context, alreadyCoveredMessage);
      }

      if (result.uncoveredSlotsCount > 0) {
        AppSnackBar.showWarning(
          context,
          result.createdAssignmentsCount == 0
              ? isItalian
                    ? 'Nessun turno creato. Restano ${result.uncoveredSlotsCount} coperture mancanti. Controlla i vincoli o amplia il team.'
                    : 'No shifts were created. ${result.uncoveredSlotsCount} slots are still uncovered. Review the constraints or expand the team.'
              : isItalian
              ? 'Restano ${result.uncoveredSlotsCount} coperture mancanti. Controlla i vincoli o amplia il team.'
              : '${result.uncoveredSlotsCount} slots are still uncovered. Review the constraints or expand the team.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _autoPlannerPreviewLoading = false);
      }
      if (!mounted || !context.mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: isItalian
            ? 'Non siamo riusciti a generare i turni automatici.'
            : 'We could not generate the automatic shifts.',
      );
    }
  }

  Map<String, String> _buildPreviewUserLabels(
    List<TeamMemberforView>? members,
  ) {
    final labels = <String, String>{};
    final combinedMembers = <TeamMemberforView>[
      ..._teamMembersByTeamId.values.expand((entry) => entry),
      if (members != null) ...members,
    ];
    for (final member in combinedMembers) {
      final userId = member.teamMember.userId?.trim();
      if (userId == null || userId.isEmpty) {
        continue;
      }
      final label = _previewUserLabel(member);
      if (label.isNotEmpty) {
        labels[userId] = label;
      }
    }
    return labels;
  }

  String _previewUserLabel(TeamMemberforView member) {
    final fullName = member.user?.fullName.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final initialName = member.teamMember.initialName?.trim();
    if (initialName != null && initialName.isNotEmpty) {
      return initialName;
    }
    final email = member.teamMember.userEmail.trim();
    if (email.isNotEmpty) {
      return email;
    }
    return member.teamMember.userId?.trim() ?? '';
  }
}
