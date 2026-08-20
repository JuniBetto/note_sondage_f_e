import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/error/error_logger.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/task_realtime_coordinator.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_text_size.dart';
import 'package:note_sondage/feature/task/notification/task_alarm_scheduler.dart';

import 'package:note_sondage/feature/task/domain/use_case/task_use_case.dart';
import 'package:note_sondage/feature/task/navigation/task_open_intent_controller.dart';
import 'package:note_sondage/feature/task/ui/bloc/task_bloc.dart';
import 'package:note_sondage/feature/task/ui/bloc/task_text_size_cubit.dart';
import 'package:note_sondage/feature/task/ui/task_density_scope.dart';
import 'package:note_sondage/feature/task/ui/task_editor_sheet.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_calendar_view.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_card.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_detail_panel.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_empty_state.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_status_filter_bar.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_table_view.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_timeline_view.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_workspace_header.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';

import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

const _kSplitViewBreakpoint = 900.0;

enum TaskViewMode { list, table, timeline, calendar }

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key, this.initialTeamId, this.embedded = false});

  final String? initialTeamId;
  final bool embedded;

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> {
  final TaskUseCase _taskUseCase = GetIt.instance<TaskUseCase>();
  // Mutazioni (create/update/status/archive) passano dal bloc, non
  // direttamente dallo use case, cosi che TaskAlarmScheduler osservi ogni
  // cambiamento e schedula/cancelli i promemoria — stesso ruolo di ShiftBloc
  // per ShiftAlarmScheduler.
  final TaskBloc _taskBloc = GetIt.instance<TaskBloc>();
  final TaskAlarmScheduler _taskAlarmScheduler =
      GetIt.instance<TaskAlarmScheduler>();
  // Lets the user shrink/grow all text in the compact/mobile layout to fit
  // more content on screen (see TaskTextSizeToggle in TaskWorkspaceHeader).
  final TaskTextSizeCubit _taskTextSizeCubit =
      GetIt.instance<TaskTextSizeCubit>();
  final TeamMemberUseCase _teamMemberUseCase =
      GetIt.instance<TeamMemberUseCase>();
  final RoleUseCase _roleUseCase = GetIt.instance<RoleUseCase>();

  String? _selectedTeamId;
  List<TaskEntity> _tasks = const <TaskEntity>[];
  List<TaskEntity> _archivedTasks = const <TaskEntity>[];
  bool _loadingTasks = false;
  bool _loadingArchivedTasks = false;
  bool _showArchived = false;
  bool _loadingAccess = false;
  Map<String, List<TeamMemberEntity>> _membersByTeamId =
      const <String, List<TeamMemberEntity>>{};
  Map<String, List<RoleEntity>> _rolesByTeamId =
      const <String, List<RoleEntity>>{};
  Set<String> _pendingMemberTeamIds = <String>{};
  Set<String> _pendingRoleTeamIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TaskStatus? _selectedStatusFilter;
  String? _selectedTaskId;
  TaskViewMode _viewMode = TaskViewMode.list;
  DateTime _timelineWeekStart = mondayOfWeek(DateTime.now());
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = GetIt.instance<RealtimeNotificationService>().stream
        .listen(_handleRealtimeNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final teams = _teams;
      _syncSelectedTeamWithTeams(teams);
      unawaited(_ensureAccessContextLoadedForTeams(teams));
      // _syncSelectedTeamWithTeams only refreshes when the selection actually
      // changes; "My Tasks" (null) is now the resting default, so the very
      // first load needs an explicit kick here.
      await _refreshTasks();
      if (!mounted) {
        return;
      }
      unawaited(_tryConsumeTaskOpenIntent());
    });
  }

  /// Refreshes the task list when another user's mutation arrives over the
  /// realtime websocket (e.g. a teammate changed a task's status) — without
  /// this, only the actor's own optimistic UI update was ever reflected and
  /// every other viewer needed a manual pull-to-refresh to see the change.
  void _handleRealtimeNotification(RealtimeNotification notification) {
    final decision = GetIt.instance<TaskRealtimeCoordinator>().resolveDecision(
      notification,
    );
    if (!decision.refreshTasks || !mounted) {
      return;
    }
    unawaited(_refreshTasks());
  }

  /// Consumes any pending deep-link intent queued by [TaskOpenIntentController]
  /// (e.g. when the user tapped a "task assigned" push notification). Must be
  /// called after tasks have been loaded so we can look up the entity by ID.
  Future<void> _tryConsumeTaskOpenIntent() async {
    final intentController = GetIt.instance<TaskOpenIntentController>();
    final intent = intentController.pendingIntent;
    if (intent == null) {
      return;
    }
    intentController.clear();
    final task = _findTaskById(intent.taskId);
    if (task == null || !mounted) {
      return;
    }
    await _openTaskDetail(task);
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  TeamState get _readTeamState => context.read<TeamBloc>().state;

  List<TeamEntity> get _teams {
    return _teamsFromState(_readTeamState);
  }

  List<TeamEntity> _teamsFromState(TeamState state) {
    if (state is! TeamsLoaded) {
      return const <TeamEntity>[];
    }
    return state.teams
        .where((team) => team.id != null && team.id!.trim().isNotEmpty)
        .toList(growable: false);
  }

  TeamEntity? get _selectedTeam {
    return _selectedTeamFrom(_teams);
  }

  TeamEntity? _selectedTeamFrom(List<TeamEntity> teams) {
    final selectedTeamId = _selectedTeamId?.trim();
    if (selectedTeamId == null || selectedTeamId.isEmpty) {
      return null;
    }
    for (final team in teams) {
      if (team.id?.trim() == selectedTeamId) {
        return team;
      }
    }
    return null;
  }

  String get _currentUid => context.read<AuthBloc>().state.user.uid.trim();

  String get _currentEmail =>
      context.read<AuthBloc>().state.user.email.trim().toLowerCase();

  String get _actorDisplayName {
    final user = context.read<AuthBloc>().state.user;
    final candidate = user.displayName?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return user.email.trim();
  }

  List<TaskEntity> _applyTaskSearch(List<TaskEntity> tasks) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return tasks;
    }
    return tasks
        .where((task) {
          final haystack = <String>[
            task.title,
            task.description ?? '',
            task.assigneeDisplayName ?? '',
            task.createdByDisplayName ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<TaskEntity> _applyStatusFilter(List<TaskEntity> tasks) {
    final status = _selectedStatusFilter;
    if (status == null) {
      return tasks;
    }
    return tasks.where((task) => task.status == status).toList(growable: false);
  }

  TaskEntity? _findTaskById(String? taskId) {
    if (taskId == null || taskId.isEmpty) {
      return null;
    }
    for (final task in _tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    for (final task in _archivedTasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  /// Mirrors Shift's default: unless a specific [widget.initialTeamId] was
  /// requested (or the user already picked a team), the page opens on "My
  /// Tasks" (no team selected) rather than forcing a team — auto-picking
  /// `teams.first` could silently land on a team the user can't manage,
  /// which the now-filtered picker wouldn't even list.
  void _syncSelectedTeamWithTeams(List<TeamEntity> teams) {
    if (teams.isEmpty) {
      return;
    }
    final candidate = _selectedTeamId?.trim().isNotEmpty == true
        ? _selectedTeamId!.trim()
        : (widget.initialTeamId?.trim().isNotEmpty == true
              ? widget.initialTeamId!.trim()
              : null);
    final exists =
        candidate != null && teams.any((team) => team.id?.trim() == candidate);
    final nextTeamId = exists ? candidate : null;
    if (_selectedTeamId == nextTeamId) {
      return;
    }
    setState(() {
      _selectedTeamId = nextTeamId;
      _selectedTaskId = null;
    });
    unawaited(_refreshTasks());
  }

  Future<void> _ensureAccessContextLoadedForTeams(
    List<TeamEntity> teams,
  ) async {
    if (teams.isEmpty) {
      return;
    }
    final memberTeamIdsToLoad = teams
        .map((team) => team.id!.trim())
        .where(
          (teamId) =>
              !_membersByTeamId.containsKey(teamId) &&
              !_pendingMemberTeamIds.contains(teamId),
        )
        .toList(growable: false);
    final roleTeamIdsToLoad = teams
        .map((team) => team.id!.trim())
        .where(
          (teamId) =>
              !_rolesByTeamId.containsKey(teamId) &&
              !_pendingRoleTeamIds.contains(teamId),
        )
        .toList(growable: false);
    if (memberTeamIdsToLoad.isEmpty && roleTeamIdsToLoad.isEmpty) {
      return;
    }
    setState(() {
      _loadingAccess = true;
      _pendingMemberTeamIds = <String>{
        ..._pendingMemberTeamIds,
        ...memberTeamIdsToLoad,
      };
      _pendingRoleTeamIds = <String>{
        ..._pendingRoleTeamIds,
        ...roleTeamIdsToLoad,
      };
    });
    try {
      final futures = <Future<void>>[];
      for (final teamId in memberTeamIdsToLoad) {
        futures.add(
          _teamMemberUseCase
              .getAllMembersByTeamId(teamId)
              .then((members) {
                _membersByTeamId = <String, List<TeamMemberEntity>>{
                  ..._membersByTeamId,
                  teamId: members,
                };
              })
              .catchError((Object error, StackTrace stack) {
                // A single slow/failed team must not crash the whole page;
                // that team is simply treated as "not manageable" until a
                // later retry succeeds (mirrors ShiftWebPage's behaviour).
                ErrorLogger.log(error, stack);
              }),
        );
      }
      for (final teamId in roleTeamIdsToLoad) {
        futures.add(
          _roleUseCase
              .getAllRolesByTeamId(teamId)
              .then((roles) {
                _rolesByTeamId = <String, List<RoleEntity>>{
                  ..._rolesByTeamId,
                  teamId: roles,
                };
              })
              .catchError((Object error, StackTrace stack) {
                ErrorLogger.log(error, stack);
              }),
        );
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      if (!mounted) {
        return;
      }
      setState(() {});
    } finally {
      if (mounted) {
        setState(() {
          _pendingMemberTeamIds = <String>{
            for (final teamId in _pendingMemberTeamIds)
              if (!memberTeamIdsToLoad.contains(teamId)) teamId,
          };
          _pendingRoleTeamIds = <String>{
            for (final teamId in _pendingRoleTeamIds)
              if (!roleTeamIdsToLoad.contains(teamId)) teamId,
          };
          _loadingAccess =
              _pendingMemberTeamIds.isNotEmpty ||
              _pendingRoleTeamIds.isNotEmpty;
        });
      }
    }
  }

  Future<void> _loadTasksForSelectedTeam() async {
    final teamId = _selectedTeamId?.trim();
    final isMyTasksMode = teamId == null || teamId.isEmpty;
    if (_tasks.isEmpty) {
      // Paint instantly from the local cache while the network fetch below
      // runs, instead of showing a blank/loading state on every switch.
      final cached = await _taskUseCase.getLocalOnly();
      if (!mounted) {
        return;
      }
      final cachedSlice = isMyTasksMode
          ? cached
                .where(
                  (task) =>
                      !task.isArchived &&
                      (task.createdByUserId == _currentUid ||
                          task.assigneeUserId == _currentUid),
                )
                .toList(growable: false)
          : cached
                .where((task) => task.teamId == teamId && !task.isArchived)
                .toList(growable: false);
      if (cachedSlice.isNotEmpty) {
        setState(() {
          _tasks = cachedSlice;
        });
      }
    }
    setState(() {
      _loadingTasks = true;
    });
    try {
      final tasks = isMyTasksMode
          ? await _taskUseCase.getMyTasks(_currentUid)
          : await _taskUseCase.getTasksByTeam(teamId);
      await _taskAlarmScheduler.syncTasks(
        tasks.where((task) => !task.isArchived),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = tasks
            .where((task) => !task.isArchived)
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.taskLoadTeamTasksError,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingTasks = false;
        });
      }
    }
  }

  Future<void> _loadArchivedTasksForSelectedTeam() async {
    final teamId = _selectedTeamId?.trim();
    final isMyTasksMode = teamId == null || teamId.isEmpty;
    if (_archivedTasks.isEmpty) {
      final cached = await _taskUseCase.getLocalOnly();
      if (!mounted) {
        return;
      }
      final cachedSlice = isMyTasksMode
          ? cached
                .where(
                  (task) =>
                      task.isArchived &&
                      (task.createdByUserId == _currentUid ||
                          task.assigneeUserId == _currentUid),
                )
                .toList(growable: false)
          : cached
                .where((task) => task.teamId == teamId && task.isArchived)
                .toList(growable: false);
      if (cachedSlice.isNotEmpty) {
        setState(() {
          _archivedTasks = cachedSlice;
        });
      }
    }
    setState(() {
      _loadingArchivedTasks = true;
    });
    try {
      final tasks = isMyTasksMode
          ? await _taskUseCase.getMyArchivedTasks(_currentUid)
          : await _taskUseCase.getArchivedTasksByTeam(teamId);
      if (!mounted) {
        return;
      }
      setState(() {
        _archivedTasks = tasks;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.taskLoadArchivedTasksError,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingArchivedTasks = false;
        });
      }
    }
  }

  Future<void> _refreshTasks() {
    return Future.wait([
      _loadTasksForSelectedTeam(),
      _loadArchivedTasksForSelectedTeam(),
    ]);
  }

  bool _canManageTeam(TeamEntity team) {
    final teamId = team.id?.trim();
    if (teamId == null || teamId.isEmpty) {
      return false;
    }
    if (team.createdByUserId.trim() == _currentUid) {
      return true;
    }
    final members = _membersByTeamId[teamId] ?? const <TeamMemberEntity>[];
    TeamMemberEntity? currentMember;
    for (final member in members) {
      if ((member.userId?.trim().isNotEmpty == true &&
              member.userId!.trim() == _currentUid) ||
          member.userEmail.trim().toLowerCase() == _currentEmail) {
        currentMember = member;
        break;
      }
    }
    final roleCode = normalizeTaskRoleCode(currentMember?.roleId);
    if (roleCode == 'OWNER' || roleCode == 'ADMIN') {
      return true;
    }
    final roles = _rolesByTeamId[teamId] ?? const <RoleEntity>[];
    final role = roles
        .where((item) => normalizeTaskRoleCode(item.id) == roleCode)
        .firstOrNull;
    final permissions = normalizeTaskPermissions(roleCode, role?.permissions);
    return permissions.contains('ADMIN') || permissions.contains('MANAGE');
  }

  /// Resolves the task's own team (not necessarily [_selectedTeamId] — a
  /// cross-team view like "My Tasks" shows tasks from several teams at once).
  TeamEntity? _teamForTask(TaskEntity task) {
    final teamId = task.teamId?.trim();
    if (teamId == null || teamId.isEmpty) {
      return null;
    }
    return _teams.where((team) => team.id?.trim() == teamId).firstOrNull;
  }

  /// A personal (team-less) task is manageable only by its creator; a team
  /// task follows the team's own management-role check.
  bool _canManageTask(TaskEntity task) {
    if (task.isPersonal) {
      return task.createdByUserId.trim() == _currentUid;
    }
    final team = _teamForTask(task);
    return team != null && _canManageTeam(team);
  }

  bool _canChangeStatus(TaskEntity task) {
    if (_canManageTask(task)) {
      return true;
    }
    if (task.isPersonal) {
      return false;
    }
    return task.assigneeUserId?.trim().isNotEmpty == true &&
        task.assigneeUserId!.trim() == _currentUid;
  }

  bool _canEditTask(TaskEntity task) => _canManageTask(task);

  Future<List<TaskAssigneeOption>> _loadAssigneeOptions(String teamId) async {
    final members =
        _membersByTeamId[teamId] ??
        await _teamMemberUseCase.getAllMembersByTeamId(teamId);
    if (!_membersByTeamId.containsKey(teamId)) {
      _membersByTeamId = <String, List<TeamMemberEntity>>{
        ..._membersByTeamId,
        teamId: members,
      };
    }
    return members
        .where((member) => member.status == UserStatus.active)
        .map((member) {
          final label =
              (member.initialName?.trim().isNotEmpty == true
                      ? member.initialName!.trim()
                      : member.userEmail.trim())
                  .trim();
          return TaskAssigneeOption(
            userId: member.userId?.trim().isNotEmpty == true
                ? member.userId!.trim()
                : member.id?.trim() ?? label,
            label: label,
            secondaryLabel: member.userEmail,
          );
        })
        .where((option) => option.userId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _openCreateTask() async {
    final l10n = AppLocalizations.of(context)!;
    final manageableTeams = _teams
        .where(_canManageTeam)
        .toList(growable: false);
    // A personal task is always creatable regardless of team management
    // rights, so — unlike before — an empty manageableTeams list no longer
    // blocks task creation; it only limits which teams the form can offer.
    final createdTask = await showTaskEditorSheet(
      context: context,
      availableTeams: manageableTeams,
      loadAssignees: _loadAssigneeOptions,
      onCreate: _taskBloc.createTask,
      onUpdate: (task, request) => _taskBloc.updateTask(task.id, request),
      actorUserId: _currentUid,
      actorDisplayName: _actorDisplayName,
      // Always pass an explicit draft (teamId may legitimately be null,
      // meaning "personal") so the editor doesn't fall back to defaulting
      // the team dropdown to the first available manageable team.
      initialDraft: TaskCreateRequestEntity(teamId: _selectedTeamId, title: ''),
    );
    if (!mounted || createdTask == null) {
      return;
    }
    AppSnackBar.showSuccess(context, l10n.taskCreateSuccess);
    if (createdTask.teamId == _selectedTeamId) {
      await _loadTasksForSelectedTeam();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTaskId = createdTask.id;
    });
    if (MediaQuery.of(context).size.width >= _kSplitViewBreakpoint) {
      // Wide layout already shows the task in the persistent side panel via
      // the selection above; opening the bottom-sheet on top would be
      // redundant.
      return;
    }
    await _openTaskDetail(createdTask);
  }

  Future<void> _openEditTask(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    final taskTeam = _teamForTask(task);
    if (!task.isPersonal && (taskTeam == null || !_canManageTeam(taskTeam))) {
      return;
    }
    final availableTeams = taskEditAvailableTeams(
      task: task,
      taskTeam: taskTeam,
      manageableTeams: _teams.where(_canManageTeam).toList(growable: false),
    );
    final updated = await showTaskEditorSheet(
      context: context,
      availableTeams: availableTeams,
      loadAssignees: _loadAssigneeOptions,
      onCreate: _taskBloc.createTask,
      onUpdate: (task, request) => _taskBloc.updateTask(task.id, request),
      actorUserId: _currentUid,
      actorDisplayName: _actorDisplayName,
      existingTask: task,
      lockTeamSelection: true,
    );
    if (!mounted || updated == null) {
      return;
    }
    AppSnackBar.showSuccess(context, l10n.taskUpdateSuccess);
    await _loadTasksForSelectedTeam();
  }

  /// Applies a status change without leaving the persistent side panel
  /// (wide/desktop layout only — the mobile bottom sheet manages its own
  /// local copy while it is open).
  Future<void> _handleInlineStatusChange(
    TaskEntity task,
    TaskStatus nextStatus,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final rollbackTasks = List<TaskEntity>.from(_tasks);
    final optimisticTask = task.copyWith(status: nextStatus);
    setState(() {
      _tasks = [
        for (final existing in _tasks)
          if (existing.id == task.id) optimisticTask else existing,
      ];
    });
    try {
      final updated = await _taskBloc.updateTaskStatus(task.id, nextStatus);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = [
          for (final existing in _tasks)
            if (existing.id == updated.id) updated else existing,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = rollbackTasks;
      });
      AppSnackBar.showError(context, l10n.taskUpdateStatusError);
    }
  }

  Future<void> _openTaskDetail(TaskEntity initialTask) async {
    TaskEntity latestTask = initialTask;
    final result = await showModalBottomSheet<_TaskDetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocBuilder<TaskTextSizeCubit, TaskTextSize>(
          bloc: _taskTextSizeCubit,
          builder: (blocContext, textSize) {
            return MediaQuery(
              data: MediaQuery.of(
                sheetContext,
              ).copyWith(textScaler: TextScaler.linear(textSize.scaleFactor)),
              child: TaskDensityScope(
                scale: textSize.scaleFactor,
                child: StatefulBuilder(
                  builder: (sheetContext, setModalState) {
                    final l10n = AppLocalizations.of(sheetContext)!;
                    final isArchivedTask = latestTask.isArchived;
                    final canChangeStatus =
                        !isArchivedTask && _canChangeStatus(latestTask);
                    final canEdit = !isArchivedTask && _canEditTask(latestTask);
                    final canRestore =
                        isArchivedTask && _canEditTask(latestTask);
                    final canDeletePermanently =
                        _canEditTask(latestTask) &&
                        (isArchivedTask ||
                            latestTask.status == TaskStatus.canceled);
                    return FractionallySizedBox(
                      heightFactor: MediaQuery.of(sheetContext).size.width < 760
                          ? 0.88
                          : 0.84,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            Expanded(
                              child: TaskDetailPanel(
                                task: latestTask,
                                canChangeStatus: canChangeStatus,
                                canEdit: canEdit,
                                canRestore: canRestore,
                                canDeletePermanently: canDeletePermanently,
                                onStatusChange: (nextStatus) async {
                                  final rollbackTask = latestTask;
                                  setModalState(() {
                                    latestTask = latestTask.copyWith(
                                      status: nextStatus,
                                    );
                                  });
                                  try {
                                    final updated = await _taskBloc
                                        .updateTaskStatus(
                                          latestTask.id,
                                          nextStatus,
                                        );
                                    if (!mounted) {
                                      return;
                                    }
                                    setModalState(() {
                                      latestTask = updated;
                                    });
                                  } catch (_) {
                                    if (!mounted) {
                                      return;
                                    }
                                    setModalState(() {
                                      latestTask = rollbackTask;
                                    });
                                    AppSnackBar.showError(
                                      context,
                                      l10n.taskUpdateStatusError,
                                    );
                                  }
                                },
                                onEdit: canEdit
                                    ? () => Navigator.of(
                                        sheetContext,
                                      ).pop(_TaskDetailAction.edit)
                                    : null,
                                onArchive: canEdit
                                    ? () => Navigator.of(
                                        sheetContext,
                                      ).pop(_TaskDetailAction.archive)
                                    : null,
                                onRestore: canRestore
                                    ? () => Navigator.of(
                                        sheetContext,
                                      ).pop(_TaskDetailAction.restore)
                                    : null,
                                onDeletePermanently: canDeletePermanently
                                    ? () => Navigator.of(
                                        sheetContext,
                                      ).pop(_TaskDetailAction.deletePermanently)
                                    : null,
                                onOpenLinkedChat: () => Navigator.of(
                                  sheetContext,
                                ).pop(_TaskDetailAction.openLinkedChat),
                                onClose: () => Navigator.of(sheetContext).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      await _refreshTasks();
      return;
    }

    switch (result) {
      case _TaskDetailAction.edit:
        await _openEditTask(latestTask);
        break;
      case _TaskDetailAction.archive:
        await _archiveTask(latestTask);
        break;
      case _TaskDetailAction.restore:
        await _restoreTask(latestTask);
        break;
      case _TaskDetailAction.deletePermanently:
        await _deleteTaskPermanently(latestTask);
        break;
      case _TaskDetailAction.openLinkedChat:
        _openLinkedChat(latestTask);
        break;
    }
  }

  Future<void> _archiveTask(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    final rollbackTasks = List<TaskEntity>.from(_tasks);
    final rollbackArchived = List<TaskEntity>.from(_archivedTasks);
    final optimisticTask = task.copyWith(archivedAt: DateTime.now());
    setState(() {
      _tasks = _tasks.where((existing) => existing.id != task.id).toList();
      _archivedTasks = [..._archivedTasks, optimisticTask];
    });
    try {
      final archived = await _taskBloc.archiveTask(task.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _archivedTasks = [
          for (final existing in _archivedTasks)
            if (existing.id == archived.id) archived else existing,
        ];
      });
      AppSnackBar.showSuccess(context, l10n.taskArchiveSuccess);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = rollbackTasks;
        _archivedTasks = rollbackArchived;
      });
      AppSnackBar.showError(context, l10n.taskArchiveError);
    }
  }

  Future<void> _restoreTask(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    final rollbackTasks = List<TaskEntity>.from(_tasks);
    final rollbackArchived = List<TaskEntity>.from(_archivedTasks);
    final optimisticTask = task.copyWith(clearArchivedAt: true);
    setState(() {
      _archivedTasks = _archivedTasks
          .where((existing) => existing.id != task.id)
          .toList();
      _tasks = [..._tasks, optimisticTask];
    });
    try {
      final restored = await _taskBloc.unarchiveTask(task.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = [
          for (final existing in _tasks)
            if (existing.id == restored.id) restored else existing,
        ];
      });
      AppSnackBar.showSuccess(context, l10n.taskRestoreSuccess);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = rollbackTasks;
        _archivedTasks = rollbackArchived;
      });
      AppSnackBar.showError(context, l10n.taskRestoreError);
    }
  }

  Future<void> _deleteTaskPermanently(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _taskBloc.deleteTaskPermanently(task);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = _tasks.where((existing) => existing.id != task.id).toList();
        _archivedTasks = _archivedTasks
            .where((existing) => existing.id != task.id)
            .toList();
        if (_selectedTaskId == task.id) {
          _selectedTaskId = null;
        }
      });
      AppSnackBar.showSuccess(context, l10n.taskDeletePermanentlySuccess);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, l10n.taskDeletePermanentlyError);
    }
  }

  void _openLinkedChat(TaskEntity task) {
    final teamId = task.workflowMetadata?.contextId?.trim();
    if (teamId == null || teamId.isEmpty) {
      return;
    }
    final path = Uri(
      path: MediaQuery.of(context).size.width < 760
          ? RouterPaths.sondageChatConversation
          : RouterPaths.chat,
      queryParameters: <String, String>{'teamId': teamId, 'focus': 'latest'},
    ).toString();
    if (MediaQuery.of(context).size.width < 760) {
      context.push(path);
      return;
    }
    context.go(path);
  }

  void _selectTask(TaskEntity task) {
    setState(() {
      _selectedTaskId = task.id;
    });
  }

  void _clearTaskSelection() {
    if (_selectedTaskId == null) {
      return;
    }
    setState(() {
      _selectedTaskId = null;
    });
  }

  Widget _buildDetailPanelCard(
    BuildContext context, {
    required TaskEntity task,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isArchivedTask = task.isArchived;
    final canChangeStatus = !isArchivedTask && _canChangeStatus(task);
    final canEdit = !isArchivedTask && _canEditTask(task);
    final canRestore = isArchivedTask && _canEditTask(task);
    final canDeletePermanently =
        _canEditTask(task) &&
        (isArchivedTask || task.status == TaskStatus.canceled);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.borderColor ?? colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TaskDetailPanel(
        key: ValueKey(task.id),
        task: task,
        canChangeStatus: canChangeStatus,
        canEdit: canEdit,
        canRestore: canRestore,
        canDeletePermanently: canDeletePermanently,
        onStatusChange: (nextStatus) =>
            _handleInlineStatusChange(task, nextStatus),
        onEdit: canEdit ? () => _openEditTask(task) : null,
        onArchive: canEdit ? () => _archiveTask(task) : null,
        onRestore: canRestore ? () => _restoreTask(task) : null,
        onDeletePermanently: canDeletePermanently
            ? () => _deleteTaskPermanently(task)
            : null,
        onOpenLinkedChat: () => _openLinkedChat(task),
        onClose: _clearTaskSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamState = context.watch<TeamBloc>().state;
    final teams = _teamsFromState(teamState);
    // Only teams the user can manage are selectable/shown in the picker —
    // mirrors Shift's team filtering exactly.
    final manageableTeams = teams.where(_canManageTeam).toList(growable: false);
    final selectedTeam = _selectedTeamFrom(teams);
    // "My Tasks" (no team selected) always allows creating a personal task;
    // a specific team requires management rights on that team.
    final canManageSelectedTeam =
        _selectedTeamId == null ||
        (selectedTeam != null && _canManageTeam(selectedTeam));
    final searchFilteredActiveTasks = _applyTaskSearch(_tasks);
    final filteredTasks = _applyStatusFilter(searchFilteredActiveTasks);
    final filteredArchivedTasks = _applyTaskSearch(_archivedTasks);
    final displayedTasks = _showArchived
        ? filteredArchivedTasks
        : filteredTasks;
    final isLoadingDisplayed = _showArchived
        ? _loadingArchivedTasks
        : _loadingTasks;
    final displayedSourceEmpty = _showArchived
        ? _archivedTasks.isEmpty
        : _tasks.isEmpty;
    final countsByStatus = <TaskStatus, int>{
      for (final status in TaskStatus.values)
        status: searchFilteredActiveTasks
            .where((task) => task.status == status)
            .length,
    };
    final selectedTask = _findTaskById(_selectedTaskId);

    if (teamState is TeamLoading && teams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocListener<TeamBloc, TeamState>(
      listener: (_, nextState) {
        final nextTeams = _teamsFromState(nextState);
        _syncSelectedTeamWithTeams(nextTeams);
        unawaited(_ensureAccessContextLoadedForTeams(nextTeams));
      },
      child: SafeArea(
        top: !widget.embedded,
        bottom: widget.embedded,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSplitView = constraints.maxWidth >= _kSplitViewBreakpoint;

            final taskListArea = RefreshIndicator(
              onRefresh: _refreshTasks,
              child: isLoadingDisplayed && displayedSourceEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : displayedTasks.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        TaskEmptyState(
                          canManageSelectedTeam: canManageSelectedTeam,
                          isArchivedView: _showArchived,
                        ),
                      ],
                    )
                  : _viewMode == TaskViewMode.table
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _HorizontalScrollIfNarrow(
                        minWidth: 640,
                        child: TaskTableView(
                          tasks: displayedTasks,
                          selectedTaskId: isSplitView ? selectedTask?.id : null,
                          onTaskTap: (task) => isSplitView
                              ? _selectTask(task)
                              : _openTaskDetail(task),
                        ),
                      ),
                    )
                  : _viewMode == TaskViewMode.timeline
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TaskTimelineView(
                        tasks: displayedTasks,
                        weekStart: _timelineWeekStart,
                        onWeekStartChanged: (value) {
                          setState(() {
                            _timelineWeekStart = value;
                          });
                        },
                        selectedTaskId: isSplitView ? selectedTask?.id : null,
                        onTaskTap: (task) => isSplitView
                            ? _selectTask(task)
                            : _openTaskDetail(task),
                      ),
                    )
                  : _viewMode == TaskViewMode.calendar
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TaskCalendarView(
                        tasks: displayedTasks,
                        weekStart: _timelineWeekStart,
                        onWeekStartChanged: (value) {
                          setState(() {
                            _timelineWeekStart = value;
                          });
                        },
                        selectedTaskId: isSplitView ? selectedTask?.id : null,
                        onTaskTap: (task) => isSplitView
                            ? _selectTask(task)
                            : _openTaskDetail(task),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        isSplitView ? 16 : 24,
                      ),
                      itemCount: displayedTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = displayedTasks[index];
                        return TaskCard(
                          task: task,
                          selected: isSplitView && task.id == selectedTask?.id,
                          onTap: () => isSplitView
                              ? _selectTask(task)
                              : _openTaskDetail(task),
                        );
                      },
                    ),
            );

            final showDetailPanel = isSplitView && selectedTask != null;

            final content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: TaskWorkspaceHeader(
                    embedded: widget.embedded,
                    teams: manageableTeams,
                    selectedTeamId: _selectedTeamId,
                    onTeamChanged: (value) {
                      if (value == _selectedTeamId) {
                        return;
                      }
                      setState(() {
                        _selectedTeamId = value;
                        _selectedTaskId = null;
                      });
                      unawaited(_refreshTasks());
                    },
                    canManageSelectedTeam: canManageSelectedTeam,
                    onCreateTask: _openCreateTask,
                    loadingAccess: _loadingAccess,
                    viewMode: _viewMode,
                    onViewModeChanged: (value) {
                      setState(() {
                        _viewMode = value;
                      });
                    },
                    searchController: _searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TaskStatusFilterBar(
                    totalCount: searchFilteredActiveTasks.length,
                    countsByStatus: countsByStatus,
                    selectedStatus: _selectedStatusFilter,
                    showArchived: _showArchived,
                    archivedCount: filteredArchivedTasks.length,
                    onStatusSelected: (status) {
                      setState(() {
                        _selectedStatusFilter = status;
                        _showArchived = false;
                      });
                    },
                    onArchivedSelected: () {
                      setState(() {
                        _showArchived = true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: !showDetailPanel
                      ? taskListArea
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Tapping anywhere that isn't a task card or the
                          // detail panel itself (the panel absorbs its own
                          // taps below) clears the selection and closes it.
                          onTap: _clearTaskSelection,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: taskListArea),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 380,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {},
                                    child: _buildDetailPanelCard(
                                      context,
                                      task: selectedTask,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );

            if (isSplitView) {
              return content;
            }

            // Compact/mobile layout only: split view has enough room that
            // shrinking/growing text to fit more content isn't the point.
            return BlocBuilder<TaskTextSizeCubit, TaskTextSize>(
              bloc: _taskTextSizeCubit,
              builder: (context, textSize) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textSize.scaleFactor),
                  ),
                  child: TaskDensityScope(
                    scale: textSize.scaleFactor,
                    child: content,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

enum _TaskDetailAction {
  edit,
  archive,
  restore,
  deletePermanently,
  openLinkedChat,
}

/// Lets [child] size itself normally on wide layouts; on narrow ones (mobile,
/// or a compact web window) it enforces [minWidth] and scrolls horizontally
/// instead of squeezing multi-column content unreadably.
class _HorizontalScrollIfNarrow extends StatelessWidget {
  const _HorizontalScrollIfNarrow({
    required this.minWidth,
    required this.child,
  });

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return child;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
