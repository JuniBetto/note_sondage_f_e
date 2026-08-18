import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';

import 'package:note_sondage/feature/task/domain/use_case/task_use_case.dart';
import 'package:note_sondage/feature/task/ui/task_editor_sheet.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_card.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_empty_state.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_meta_chip.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_workspace_header.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';

import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key, this.initialTeamId, this.embedded = false});

  final String? initialTeamId;
  final bool embedded;

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> {
  final TaskUseCase _taskUseCase = GetIt.instance<TaskUseCase>();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final teams = _teams;
      _syncSelectedTeamWithTeams(teams);
      unawaited(_ensureAccessContextLoadedForTeams(teams));
    });
  }

  @override
  void dispose() {
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
    final nextTeamId = exists ? candidate : teams.first.id!.trim();
    if (_selectedTeamId == nextTeamId) {
      return;
    }
    setState(() {
      _selectedTeamId = nextTeamId;
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
          _teamMemberUseCase.getAllMembersByTeamId(teamId).then((members) {
            _membersByTeamId = <String, List<TeamMemberEntity>>{
              ..._membersByTeamId,
              teamId: members,
            };
          }),
        );
      }
      for (final teamId in roleTeamIdsToLoad) {
        futures.add(
          _roleUseCase.getAllRolesByTeamId(teamId).then((roles) {
            _rolesByTeamId = <String, List<RoleEntity>>{
              ..._rolesByTeamId,
              teamId: roles,
            };
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
    if (teamId == null || teamId.isEmpty) {
      return;
    }
    setState(() {
      _loadingTasks = true;
    });
    try {
      final tasks = await _taskUseCase.getTasksByTeam(teamId);
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
    if (teamId == null || teamId.isEmpty) {
      return;
    }
    setState(() {
      _loadingArchivedTasks = true;
    });
    try {
      final tasks = await _taskUseCase.getArchivedTasksByTeam(teamId);
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

  bool _canChangeStatus(TaskEntity task) {
    final selectedTeam = _selectedTeam;
    if (selectedTeam != null && _canManageTeam(selectedTeam)) {
      return true;
    }
    return task.assigneeUserId?.trim().isNotEmpty == true &&
        task.assigneeUserId!.trim() == _currentUid;
  }

  bool _canEditTask(TaskEntity task) {
    final selectedTeam = _selectedTeam;
    return selectedTeam != null && _canManageTeam(selectedTeam);
  }

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
    if (manageableTeams.isEmpty) {
      AppSnackBar.showWarning(context, l10n.taskCreatePermissionDenied);
      return;
    }
    final createdTask = await showTaskEditorSheet(
      context: context,
      availableTeams: manageableTeams,
      loadAssignees: _loadAssigneeOptions,
      onCreate: _taskUseCase.createTask,
      onUpdate: (task, request) => _taskUseCase.updateTask(task.id, request),
      actorUserId: _currentUid,
      actorDisplayName: _actorDisplayName,
      initialDraft: _selectedTeamId != null
          ? TaskCreateRequestEntity(teamId: _selectedTeamId!, title: '')
          : null,
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
    await _openTaskDetail(createdTask);
  }

  Future<void> _openEditTask(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedTeam = _selectedTeam;
    if (selectedTeam == null || !_canManageTeam(selectedTeam)) {
      return;
    }
    final updated = await showTaskEditorSheet(
      context: context,
      availableTeams: [selectedTeam],
      loadAssignees: _loadAssigneeOptions,
      onCreate: _taskUseCase.createTask,
      onUpdate: (task, request) => _taskUseCase.updateTask(task.id, request),
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

  Future<void> _openTaskDetail(TaskEntity initialTask) async {
    TaskEntity latestTask = initialTask;
    final result = await showModalBottomSheet<_TaskDetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final l10n = AppLocalizations.of(sheetContext)!;
            final isArchivedTask = latestTask.isArchived;
            final canChangeStatus =
                !isArchivedTask && _canChangeStatus(latestTask);
            final canEdit = !isArchivedTask && _canEditTask(latestTask);
            final canRestore = isArchivedTask && _canEditTask(latestTask);
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
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            latestTask.title,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              TaskMetaChip(
                                label: taskStatusLabel(
                                  latestTask.status,
                                  sheetContext,
                                ),
                                color: taskStatusColor(
                                  latestTask.status,
                                  Theme.of(sheetContext).colorScheme,
                                ),
                              ),
                              TaskMetaChip(
                                label: taskPriorityLabel(
                                  latestTask.priority,
                                  sheetContext,
                                ),
                                color: taskPriorityColor(
                                  latestTask.priority,
                                  Theme.of(sheetContext).colorScheme,
                                ),
                              ),
                              if (latestTask.assigneeDisplayName != null)
                                TaskMetaChip(
                                  label:
                                      '${l10n.taskAssignedLabel}: ${latestTask.assigneeDisplayName}',
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.primary,
                                ),
                              if (isArchivedTask)
                                TaskMetaChip(
                                  label: l10n.taskArchivedLabel,
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (latestTask.description?.trim().isNotEmpty == true)
                            Text(latestTask.description!.trim()),
                          if (latestTask.description?.trim().isNotEmpty == true)
                            const SizedBox(height: 18),
                          _TaskDetailRow(
                            label: l10n.taskDueDateLabel,
                            value: latestTask.dueAt == null
                                ? l10n.taskDueDateNotSet
                                : taskDateTimeLabel(
                                    latestTask.dueAt!,
                                    sheetContext,
                                  ),
                          ),
                          _TaskDetailRow(
                            label: l10n.taskCreatedByLabel,
                            value:
                                latestTask.createdByDisplayName
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? latestTask.createdByDisplayName!.trim()
                                : latestTask.createdByUserId,
                          ),
                          _TaskDetailRow(
                            label: l10n.taskUpdatedLabel,
                            value: taskDateTimeLabel(
                              latestTask.updatedAt,
                              sheetContext,
                            ),
                          ),
                          if (latestTask.workflowMetadata?.sourceMessageId
                                  ?.trim()
                                  .isNotEmpty ==
                              true)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(sheetContext)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.taskSourceChatMessage,
                                        style: Theme.of(sheetContext)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      if (latestTask.workflowMetadata?.contextId
                                              ?.trim()
                                              .isNotEmpty ==
                                          true)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.of(sheetContext).pop(
                                                _TaskDetailAction
                                                    .openLinkedChat,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                            ),
                                            label: Text(
                                              l10n.taskOpenLinkedConversation,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          if (canChangeStatus)
                            DropdownButtonFormField<TaskStatus>(
                              initialValue: latestTask.status,
                              decoration: InputDecoration(
                                labelText: l10n.taskUpdateStatusLabel,
                              ),
                              items: allowedTaskStatuses(latestTask)
                                  .map(
                                    (status) => DropdownMenuItem<TaskStatus>(
                                      value: status,
                                      child: Text(
                                        taskStatusLabel(status, sheetContext),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (nextStatus) async {
                                if (nextStatus == null ||
                                    nextStatus == latestTask.status) {
                                  return;
                                }
                                try {
                                  final updated = await _taskUseCase
                                      .updateTaskStatus(
                                        latestTask.id,
                                        nextStatus,
                                      );
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() {
                                    latestTask = updated;
                                  });
                                  setModalState(() {});
                                } catch (error) {
                                  if (!mounted) {
                                    return;
                                  }
                                  AppSnackBar.showError(
                                    context,
                                    l10n.taskUpdateStatusError,
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: 18),
                          if (canEdit)
                            FilledButton.tonalIcon(
                              onPressed: () => Navigator.of(
                                sheetContext,
                              ).pop(_TaskDetailAction.edit),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(l10n.taskEditAction),
                            ),
                          if (canEdit)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(
                                  sheetContext,
                                ).pop(_TaskDetailAction.archive),
                                icon: const Icon(Icons.archive_outlined),
                                label: Text(l10n.taskArchiveAction),
                              ),
                            ),
                          if (canRestore)
                            FilledButton.tonalIcon(
                              onPressed: () => Navigator.of(
                                sheetContext,
                              ).pop(_TaskDetailAction.restore),
                              icon: const Icon(Icons.unarchive_outlined),
                              label: Text(l10n.taskRestoreAction),
                            ),
                        ],
                      ),
                    ),
                  ],
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
      case _TaskDetailAction.openLinkedChat:
        _openLinkedChat(latestTask);
        break;
    }
  }

  Future<void> _archiveTask(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _taskUseCase.archiveTask(task.id);
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, l10n.taskArchiveSuccess);
      await _refreshTasks();
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, l10n.taskArchiveError);
    }
  }

  Future<void> _restoreTask(TaskEntity task) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _taskUseCase.unarchiveTask(task.id);
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, l10n.taskRestoreSuccess);
      await _refreshTasks();
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, l10n.taskRestoreError);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamState = context.watch<TeamBloc>().state;
    final teams = _teamsFromState(teamState);
    final selectedTeam = _selectedTeamFrom(teams);
    final canManageSelectedTeam =
        selectedTeam != null && _canManageTeam(selectedTeam);
    final filteredTasks = _applyTaskSearch(_tasks);
    final filteredArchivedTasks = _applyTaskSearch(_archivedTasks);
    final displayedTasks = _showArchived ? filteredArchivedTasks : filteredTasks;
    final isLoadingDisplayed = _showArchived
        ? _loadingArchivedTasks
        : _loadingTasks;
    final displayedSourceEmpty = _showArchived
        ? _archivedTasks.isEmpty
        : _tasks.isEmpty;
    final openTasks = filteredTasks
        .where((task) => task.status == TaskStatus.open)
        .length;
    final inProgressTasks = filteredTasks
        .where((task) => task.status == TaskStatus.inProgress)
        .length;
    final doneTasks = filteredTasks
        .where((task) => task.status == TaskStatus.done)
        .length;

    if (teamState is TeamLoading && teams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.taskNoTeamsAvailable,
            textAlign: TextAlign.center,
          ),
        ),
      );
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TaskWorkspaceHeader(
                embedded: widget.embedded,
                teams: teams,
                selectedTeamId: _selectedTeamId,
                onTeamChanged: (value) {
                  if (value == null || value == _selectedTeamId) {
                    return;
                  }
                  setState(() {
                    _selectedTeamId = value;
                  });
                  unawaited(_refreshTasks());
                },
                canManageSelectedTeam: canManageSelectedTeam,
                onCreateTask: _openCreateTask,
                loadingAccess: _loadingAccess,
                totalTasks: filteredTasks.length,
                openTasks: openTasks,
                inProgressTasks: inProgressTasks,
                doneTasks: doneTasks,
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: ArchiveViewToggle(
                  showArchivedOnly: _showArchived,
                  primaryCount: filteredTasks.length,
                  archivedCount: filteredArchivedTasks.length,
                  primaryLabel: l10n.taskFilterActive,
                  archivedLabel: l10n.taskFilterArchived,
                  onChanged: (value) {
                    setState(() {
                      _showArchived = value;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
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
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: displayedTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = displayedTasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => _openTaskDetail(task),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TaskDetailAction { edit, archive, restore, openLinkedChat }

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
