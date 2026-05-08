import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_archived_assignments_list.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_entries_sheet.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_profile_manager.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';

class ShiftWebPage extends StatefulWidget {
  const ShiftWebPage({super.key});

  @override
  State<ShiftWebPage> createState() => _ShiftWebPageState();
}

class _ShiftWebPageState extends State<ShiftWebPage> {
  final TeamBloc _teamBloc = GetIt.instance<TeamBloc>();
  final TeamMemberBloc _teamMemberBloc = GetIt.instance<TeamMemberBloc>();
  final RoleUseCase _roleUseCase = GetIt.instance<RoleUseCase>();
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

  bool get _isOwnerOfAnyTeam => _teams.any(
    (team) => team.id != null && team.createdByUserId == _currentUid,
  );

  bool get _canManageAnyTeam => _manageableTeams.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadAssignments();
    _teamBloc.add(LoadTeamsEvent());
    unawaited(_loadArchivedAssignments());
    _realtimeSubscription = GetIt.instance<RealtimeNotificationService>().stream
        .listen(_handleRealtimeNotification);
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

  void _loadProfiles() =>
      context.read<ShiftBloc>().add(LoadShiftProfilesEvent());

  void _loadAssignments() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    context.read<ShiftBloc>().add(
      LoadShiftAssignmentsEvent(from: first, to: last),
    );
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
      // Keep public-shift management closed unless the role can be verified.
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
    final result = await showShiftDayDialog(
      context: context,
      date: date,
      profiles: _profiles,
      existing: existing,
      canManagePublicShifts: existing == null
          ? _canManageAnyTeam
          : _canManageAssignment(existing),
      ownerTeams: _manageableTeams,
    );
    if (result == null) return;

    if (result.archived && existing != null) {
      await _setAssignmentArchived(existing, true);
      return;
    }

    if (result.deleted && existing != null) {
      final assignmentsToDelete = _relatedPublicAssignments(existing);
      for (final assignment in assignmentsToDelete) {
        context.read<ShiftBloc>().add(
          DeleteShiftAssignmentEvent(assignment.id),
        );
      }
      return;
    }

    if (existing != null) {
      // ── public → privato: cancella tutti i turni degli altri membri ──────
      final wasPublic = existing.isPublic;
      final nowPrivate = !result.isPublic;
      if (wasPublic && nowPrivate && existing.teamId != null) {
        final toDelete = _relatedPublicAssignments(
          existing,
        ).where((assignment) => assignment.id != existing.id);
        for (final a in toDelete) {
          context.read<ShiftBloc>().add(DeleteShiftAssignmentEvent(a.id));
        }
      }
      context.read<ShiftBloc>().add(
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
          // Pass the new target only when the manager picked a different member.
          targetUserId: result.isPublic && result.targetUserIds.length == 1
              ? result.targetUserIds.first
              : null,
        ),
      );
      return;
    }

    final targetUserIds = result.targetUserIds.isEmpty
        ? const <String?>[null]
        : result.targetUserIds.cast<String?>();
    for (final targetUserId in targetUserIds) {
      context.read<ShiftBloc>().add(
        AssignShiftEvent(
          shiftDate: date,
          profileId: result.profileId,
          startTime: result.startTime,
          endTime: result.endTime,
          overnight: result.overnight,
          note: result.note,
          alarmOffsets: result.alarmOffsets,
          isPublic: result.isPublic,
          teamId: result.isPublic ? result.teamId : null,
          targetUserId: targetUserId,
        ),
      );
    }
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
          _isSameShiftTime(assignment, existing) &&
          assignment.overnight == existing.overnight &&
          (assignment.profileId == existing.profileId ||
              assignment.profileName == existing.profileName),
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
    );
    if (!mounted || action == null) return;

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final foregroundAssignments = _assignments
        .where((assignment) => !_archivedAssignmentIds.contains(assignment.id))
        .toList();
    final archivedAssignments = _assignments
        .where((assignment) => _archivedAssignmentIds.contains(assignment.id))
        .toList();

    return MultiBlocListener(
      listeners: [
        BlocListener<ShiftBloc, ShiftState>(
          listener: (context, state) {
            if (state is ShiftProfilesLoaded) {
              setState(() => _profiles = state.profiles);
            }
            if (state is ShiftAssignmentsLoaded) {
              setState(() => _assignments = state.assignments);
              // Open the specific shift if we arrived here via a notification tap
              _tryConsumeShiftOpenIntent(context);
            }
            if (state is ShiftAssigned ||
                state is ShiftAssignmentUpdated ||
                state is ShiftAssignmentDeleted) {
              _loadAssignments();
            }
            if (state is ShiftProfileCreated ||
                state is ShiftProfileUpdated ||
                state is ShiftProfileDeleted) {
              _loadProfiles();
            }
            if (state is ShiftError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.errorColor,
                ),
              );
            }
          },
        ),
        BlocListener<TeamBloc, TeamState>(
          bloc: _teamBloc,
          listener: (context, state) {
            if (state is TeamsLoaded) {
              setState(() => _teams = state.teams);
              _ensureTeamAccessContextLoaded(state.teams);
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
            }
            if (state is TeamMemberError) {
              _loadingTeamMemberIds.clear();
            }
          },
        ),
      ],
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // ═══════════════════════════════
              // Header
              // ═══════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.bgNavbarSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: appPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: appPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.shiftCalendar,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.iconLabel,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.shiftCalendarSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    if (_canManageAnyTeam)
                      Tooltip(
                        message:
                            'Team manager - puoi gestire i turni pubblici del team',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: appPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor.withValues(alpha: 0.9),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 14,
                                color: appPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Manager',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ArchiveViewToggle(
                showArchivedOnly: _showArchivedOnly,
                primaryCount: foregroundAssignments.length,
                archivedCount: archivedAssignments.length,
                primaryLabel: 'Calendario',
                archivedLabel: 'Archivio turni',
                onChanged: (value) {
                  setState(() => _showArchivedOnly = value);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _showArchivedOnly
                          ? ShiftArchivedAssignmentsList(
                              assignments: archivedAssignments,
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
                          : ShiftCalendarWidget(
                              assignments: foregroundAssignments,
                              focusedMonth: _focusedMonth,
                              onMonthChanged: _onMonthChanged,
                              onDayTap: (date, assignments) =>
                                  _onDayTap(context, date, assignments),
                            ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 280,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ShiftProfileManager(
                            profiles: _profiles,
                            isOwner: _isOwnerOfAnyTeam,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
