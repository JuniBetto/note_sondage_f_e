import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_archived_assignments_list.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
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
  final ShiftRepository _shiftRepository = GetIt.instance<ShiftRepository>();
  final UserArchiveService _archiveService =
      GetIt.instance<UserArchiveService>();
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  DateTime _focusedMonth = DateTime.now();
  List<ShiftAssignmentEntity> _assignments = [];
  List<ShiftProfileEntity> _profiles = [];
  List<TeamEntity> _teams = [];
  final Map<String, List<TeamMemberforView>> _teamMembersByTeamId = {};
  final Map<String, List<RoleEntity>> _rolesByTeamId = {};
  final Set<String> _loadingTeamMemberIds = <String>{};
  final Set<String> _loadingTeamRoleIds = <String>{};
  Set<String> _archivedAssignmentIds = <String>{};
  bool _showArchivedOnly = false;
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

  TeamEntityForView? get _selectedCalendarTeam {
    final selectedId = _selectedCalendarTeamId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    return _manageableTeams
        .where((team) => team.team.id == selectedId)
        .firstOrNull;
  }

  List<ShiftAssignmentEntity> _filterAssignmentsForSelectedCalendarTeam(
    List<ShiftAssignmentEntity> assignments,
  ) {
    final selectedTeamId = _selectedCalendarTeamId;
    if (selectedTeamId == null || selectedTeamId.isEmpty) {
      return assignments;
    }
    return assignments
        .where((assignment) => assignment.teamId == selectedTeamId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadAssignments();
    final teamState = _teamBloc.state;
    if (teamState is TeamsLoaded) {
      _teams = teamState.teams;
      _ensureTeamAccessContextLoaded(teamState.teams);
    } else if (teamState is! TeamLoading) {
      _teamBloc.add(LoadTeamsEvent());
    }
    unawaited(_loadArchivedAssignments());
    _realtimeSubscription = GetIt.instance<RealtimeNotificationService>().stream
        .listen(_handleRealtimeNotification);
    // Se arrivando sulla pagina c'è già un intent pendente (es. tap su
    // notifica allarme mentre si era già sulla pagina shift), consumalo
    // al primo frame disponibile dopo che lo stato è già ShiftAssignmentsLoaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shiftState = context.read<ShiftBloc>().state;
      if (shiftState is ShiftAssignmentsLoaded) {
        _tryConsumeShiftOpenIntent(context);
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
    final selectedTeam = _selectedCalendarTeam;
    final visibleTeamIds = selectedTeam == null
        ? const <String>[]
        : <String>[
            selectedTeam.team.id ?? '',
          ].where((teamId) => teamId.isNotEmpty).toList();
    final visibleUserIds =
        (selectedTeam?.members ?? const <TeamMemberforView>[])
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

  void _upsertAssignment(ShiftAssignmentEntity assignment) {
    final next = <ShiftAssignmentEntity>[
      ..._assignments.where((item) => item.id != assignment.id),
      assignment,
    ]..sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
    setState(() => _assignments = next);
  }

  void _removeAssignment(String assignmentId) {
    setState(() {
      _assignments = _assignments
          .where((assignment) => assignment.id != assignmentId)
          .toList();
      _archivedAssignmentIds = _archivedAssignmentIds
          .where((id) => id != assignmentId)
          .toSet();
    });
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
    final decision = GetIt.instance<ShiftRealtimeCoordinator>().resolveDecision(
      notification,
      currentUserId: _currentUid,
    );
    if (!decision.refreshCalendar || !mounted) {
      return;
    }
    _loadAssignments();
  }

  /// Consumes any pending deep-link intent queued by [ShiftOpenIntentController]
  /// (e.g. when the user tapped a push notification). Must be called after
  /// assignments have been loaded so we can look up the entity by ID.
  void _tryConsumeShiftOpenIntent(BuildContext context) {
    final intentController = GetIt.instance<ShiftOpenIntentController>();
    final intent = intentController.pendingIntent;
    if (intent == null) return;
    intentController.clear();

    final date = intent.shiftDate;
    if (date == null) return;

    // Navigate to the correct month first
    if (date.year != _focusedMonth.year || date.month != _focusedMonth.month) {
      setState(() => _focusedMonth = date);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ShiftAssignmentEntity? existing;
      if (intent.assignmentId != null) {
        existing = _assignments
            .where((a) => a.id == intent.assignmentId)
            .firstOrNull;
      }
      // Fallback: match by date if no assignmentId or not found
      if (existing == null) {
        final matches = _assignments
            .where(
              (a) =>
                  a.shiftDate.year == date.year &&
                  a.shiftDate.month == date.month &&
                  a.shiftDate.day == date.day,
            )
            .toList();
        if (matches.length == 1) existing = matches.first;
      }
      await _openDialogForAssignment(context, date, existing: existing);
    });
  }

  bool _canManageAssignment(ShiftAssignmentEntity assignment) {
    if (!assignment.isPublic) {
      return assignment.userId == _currentUid;
    }
    return assignment.teamId != null &&
        _manageableTeams.any((team) => team.team.id == assignment.teamId);
  }

  bool _canRequestAssignmentChange(ShiftAssignmentEntity assignment) {
    return assignment.isPublic &&
        assignment.userId == _currentUid &&
        !assignment.memberEditUnlocked &&
        !_canManageAssignment(assignment);
  }

  bool _canEditApprovedAssignment(ShiftAssignmentEntity assignment) {
    return assignment.isPublic &&
        assignment.userId == _currentUid &&
        assignment.memberEditUnlocked &&
        !_canManageAssignment(assignment);
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
  }) async {
    final shiftBloc = context.read<ShiftBloc>();
    final result = await showShiftDayDialog(
      context: context,
      date: date,
      profiles: _profiles,
      existing: existing,
      canManagePublicShifts: existing == null
          ? _canManageAnyTeam
          : _canManageAssignment(existing),
      canRequestPublicShiftChanges: existing != null
          ? _canRequestAssignmentChange(existing)
          : false,
      hasPendingPublicShiftChangeRequest: existing != null
          ? _hasPendingAssignmentChangeRequest(existing)
          : false,
      canEditApprovedPublicShift: existing != null
          ? _canEditApprovedAssignment(existing)
          : false,
      ownerTeams: _manageableTeams,
    );
    if (result == null) return;
    if (!context.mounted) return;

    if (result.requestedChange && existing != null) {
      await _requestAssignmentChange(context, existing, result);
      return;
    }

    if (result.archived && existing != null) {
      await _setAssignmentArchived(existing, true);
      return;
    }

    if (result.deleted && existing != null) {
      if (existing.teamShiftGroupId != null && existing.isPublic) {
        shiftBloc.add(DeleteShiftAssignmentEvent(existing.id));
      } else {
        final assignmentsToDelete = _relatedPublicAssignments(existing);
        for (final assignment in assignmentsToDelete) {
          shiftBloc.add(DeleteShiftAssignmentEvent(assignment.id));
        }
      }
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

    final scheduledDates = result.scheduledDates.isEmpty
        ? <DateTime>[date]
        : result.scheduledDates;
    final targetUserIds = result.targetUserIds.isEmpty
        ? const <String?>[null]
        : result.targetUserIds.cast<String?>();
    final uuid = const Uuid();
    final hasMemberSpecificPlans = result.memberAssignmentPlans.isNotEmpty;
    for (final scheduledDate in scheduledDates) {
      if (hasMemberSpecificPlans) {
        for (final plan in result.memberAssignmentPlans) {
          shiftBloc.add(
            AssignShiftEvent(
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
            ),
          );
        }
        continue;
      }
      final sharedGroupId = result.isPublic ? uuid.v4() : null;
      for (final targetUserId in targetUserIds) {
        shiftBloc.add(
          AssignShiftEvent(
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
          ),
        );
      }
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

  bool _hasPendingAssignmentChangeRequest(ShiftAssignmentEntity assignment) {
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
    if (!existing.isPublic || existing.teamId == null) {
      return [existing];
    }

    return _assignments.where(
      (assignment) =>
          assignment.isPublic &&
          assignment.teamId == existing.teamId &&
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
    final sortedAssignments = [...assignments]
      ..sort((a, b) {
        final byTime = a.startTime.hour * 60 + a.startTime.minute;
        final otherTime = b.startTime.hour * 60 + b.startTime.minute;
        return byTime.compareTo(otherTime);
      });

    if (sortedAssignments.isEmpty) {
      await _openDialogForAssignment(context, date);
      return;
    }

    if (sortedAssignments.length == 1) {
      await _openDialogForAssignment(
        context,
        date,
        existing: sortedAssignments.first,
      );
      return;
    }

    final action = await showShiftDayEntriesSheet(
      context: context,
      date: date,
      assignments: sortedAssignments,
      canCreate: true,
      syncingAssignmentIds: shiftBloc.syncingAssignmentIds,
    );
    if (!context.mounted || action == null) return;

    switch (action.type) {
      case ShiftDayEntriesActionType.createNew:
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
              _removeAssignment(state.assignmentId);
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
                    !_manageableTeams.any(
                      (team) => team.team.id == selectedTeamId,
                    )) {
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
            if (state is TeamMembersLoaded && state.members.isNotEmpty) {
              final teamId = state.members.first.teamId;
              _loadingTeamMemberIds.remove(teamId);
              setState(() {
                _teamMembersByTeamId[teamId] = state.members
                    .map((member) => TeamMemberforView(teamMember: member))
                    .toList();
              });
              _loadAssignments();
            }
            if (state is TeamMemberError) {
              _loadingTeamMemberIds.clear();
            }
          },
        ),
      ],
      child: Padding(
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
                if (_canManageAnyTeam) ...[
                  IconButton.outlined(
                    tooltip: loc.shiftTeamReportTooltip,
                    onPressed: () => _openTeamReport(context),
                    icon: Icon(
                      Icons.assessment_outlined,
                      size: 18,
                      color: colorScheme.textInvertedColor,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.bgNavbarbutton,
                      side: BorderSide(color: colorScheme.bgNavbarbutton!),
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
                    backgroundColor: colorScheme.bgNavbarbutton,
                    side: BorderSide(color: colorScheme.bgNavbarbutton!),
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
                    ? (_isItalian(context) ? 'Archivio turni' : 'Shift archive')
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
                child: _showArchivedOnly
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
                          syncingAssignmentIds: context
                              .read<ShiftBloc>()
                              .syncingAssignmentIds,
                          focusedMonth: _focusedMonth,
                          onMonthChanged: _onMonthChanged,
                          onDayTap: (date, assignments) =>
                              _onDayTap(context, date, assignments),
                        ),
                      ),
              ),
            ),
          ],
        ),
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
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'mobile-shifts',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_archiveToggleKey, _calendarKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }

  Future<void> _openTeamReport(BuildContext context) async {
    await ShiftTeamReportDialog.show(
      context,
      teams: _manageableTeams,
      compact: true,
    );
  }
}
