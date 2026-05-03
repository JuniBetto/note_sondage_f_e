import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_entries_sheet.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Mobile widget embedded inside the clocking section (or standalone).
class ShiftMobileWidget extends StatefulWidget {
  const ShiftMobileWidget({super.key});

  @override
  State<ShiftMobileWidget> createState() => _ShiftMobileWidgetState();
}

class _ShiftMobileWidgetState extends State<ShiftMobileWidget> {
  final TeamBloc _teamBloc = GetIt.instance<TeamBloc>();
  final TeamMemberBloc _teamMemberBloc = GetIt.instance<TeamMemberBloc>();
  final RoleUseCase _roleUseCase = GetIt.instance<RoleUseCase>();
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  DateTime _focusedMonth = DateTime.now();
  List<ShiftAssignmentEntity> _assignments = [];
  List<ShiftProfileEntity> _profiles = [];
  List<TeamEntity> _teams = [];
  final Map<String, List<TeamMemberforView>> _teamMembersByTeamId = {};
  final Map<String, List<RoleEntity>> _rolesByTeamId = {};
  final Set<String> _loadingTeamMemberIds = <String>{};
  final Set<String> _loadingTeamRoleIds = <String>{};

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

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadAssignments();
    _teamBloc.add(LoadTeamsEvent());
    _realtimeSubscription = GetIt.instance<RealtimeNotificationService>()
        .stream
        .listen(_handleRealtimeNotification);
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
    context.read<ShiftBloc>().add(
      LoadShiftAssignmentsEvent(from: first, to: last),
    );
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
      if (!_rolesByTeamId.containsKey(teamId) && _loadingTeamRoleIds.add(teamId)) {
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

    if (result.deleted && existing != null) {
      context.read<ShiftBloc>().add(DeleteShiftAssignmentEvent(existing.id));
      return;
    }

    if (existing != null) {
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

    return MultiBlocListener(
      listeners: [
        BlocListener<ShiftBloc, ShiftState>(
          listener: (context, state) {
            if (state is ShiftProfilesLoaded) {
              setState(() => _profiles = state.profiles);
            }
            if (state is ShiftAssignmentsLoaded) {
              setState(() => _assignments = state.assignments);
            }
            if (state is ShiftAssigned ||
                state is ShiftAssignmentUpdated ||
                state is ShiftAssignmentDeleted) {
              _loadAssignments();
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.descriptionColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.myShifts,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_canManageAnyTeam) ...[
                  const Spacer(),
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 16,
                    color: colorScheme.descriptionColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ShiftCalendarWidget(
              assignments: _assignments,
              focusedMonth: _focusedMonth,
              onMonthChanged: _onMonthChanged,
              onDayTap: (date, assignments) =>
                  _onDayTap(context, date, assignments),
            ),
          ],
        ),
      ),
    );
  }
}
