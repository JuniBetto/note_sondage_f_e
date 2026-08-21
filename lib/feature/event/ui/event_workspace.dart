import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/navigation/event_open_intent_controller.dart';
import 'package:note_sondage/feature/event/domain/use_case/event_use_case.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_calendar_view.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_editor_dialog.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_empty_state.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_list_card.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_workspace_header.dart';
import 'package:note_sondage/feature/notification/realtime/event_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

enum EventViewMode { card, calendar }

class EventWorkspace extends StatefulWidget {
  const EventWorkspace({
    super.key,
    this.initialTeamId,
    this.initialEventId,
    this.embedded = false,
  });

  final String? initialTeamId;
  final String? initialEventId;
  final bool embedded;

  @override
  State<EventWorkspace> createState() => _EventWorkspaceState();
}

class _EventWorkspaceState extends State<EventWorkspace> {
  final EventUseCase _eventUseCase = GetIt.instance<EventUseCase>();
  final TeamMemberBloc _teamMemberBloc = GetIt.instance<TeamMemberBloc>();
  final RoleUseCase _roleUseCase = GetIt.instance<RoleUseCase>();

  /// `null` means "My Events" — the caller's own events across every team,
  /// mirroring Shift's model rather than a single always-selected team.
  String? _selectedTeamId;
  List<EventEntity> _events = const <EventEntity>[];
  List<EventEntity> _archivedEvents = const <EventEntity>[];
  bool _loading = false;
  bool _loadingArchived = false;
  bool _showArchived = false;
  EventViewMode _viewMode = EventViewMode.card;
  DateTime _calendarWeekStart = mondayOfWeek(DateTime.now());
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  final Map<String, List<TeamMemberforView>> _teamMembersByTeamId = {};
  final Map<String, List<RoleEntity>> _rolesByTeamId = {};
  final Set<String> _loadingTeamMemberIds = <String>{};
  final Set<String> _loadingTeamRoleIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedTeamId = _normalizeOptionalId(widget.initialTeamId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _refresh();
      if (!mounted) {
        return;
      }
      unawaited(_tryOpenRequestedEvent(initialEventId: widget.initialEventId));
    });
    _realtimeSubscription = GetIt.instance<RealtimeNotificationService>().stream
        .listen(_handleRealtimeNotification);
  }

  @override
  void didUpdateWidget(covariant EventWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextInitialTeamId = _normalizeOptionalId(widget.initialTeamId);
    final previousInitialTeamId = _normalizeOptionalId(oldWidget.initialTeamId);
    final nextInitialEventId = _normalizeOptionalId(widget.initialEventId);
    final previousInitialEventId = _normalizeOptionalId(
      oldWidget.initialEventId,
    );
    if (nextInitialTeamId == previousInitialTeamId &&
        nextInitialEventId == previousInitialEventId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (_selectedTeamId != nextInitialTeamId) {
        setState(() {
          _selectedTeamId = nextInitialTeamId;
          _events = const <EventEntity>[];
          _archivedEvents = const <EventEntity>[];
          if (nextInitialEventId == null) {
            _showArchived = false;
          }
        });
        await _refresh();
      }
      if (!mounted || nextInitialEventId == null) {
        return;
      }
      unawaited(
        _tryOpenRequestedEvent(
          initialEventId: nextInitialEventId,
          preferPendingIntent: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  /// Refreshes the events list when another user's mutation arrives over the
  /// realtime websocket, mirroring [TaskRealtimeCoordinator]'s role for the
  /// Task feature — without this, every other viewer would need a manual
  /// pull-to-refresh to see the change.
  void _handleRealtimeNotification(RealtimeNotification notification) {
    final decision = GetIt.instance<EventRealtimeCoordinator>().resolveDecision(
      notification,
    );
    if (!decision.refreshEvents || !mounted) {
      return;
    }
    unawaited(_refresh());
    if (_showArchived) {
      unawaited(_loadArchivedIfNeeded(force: true));
    }
  }

  List<TeamEntity> get _teams {
    final state = context.watch<TeamBloc>().state;
    if (state is! TeamsLoaded) {
      return const <TeamEntity>[];
    }
    return state.teams
        .where((team) => team.id != null && team.id!.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Only teams the user can manage are selectable/shown in the picker —
  /// mirrors Shift/Task's team filtering exactly (Owner/Admin or a role with
  /// ADMIN/MANAGE permission). A plain member can still see events they were
  /// added to via "My Events", even in a team that never appears here.
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

  String get _currentUid => GetIt.instance<AuthBloc>().state.user.uid.trim();

  String get _currentEmail =>
      GetIt.instance<AuthBloc>().state.user.email.trim().toLowerCase();

  String get _actorUserId => _currentUid;

  String get _actorDisplayName {
    final user = GetIt.instance<AuthBloc>().state.user;
    final candidate = user.displayName?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return user.email.trim();
  }

  String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
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
      // Keep the team out of the manageable set unless the role can be verified.
    } finally {
      _loadingTeamRoleIds.remove(teamId);
    }
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

  Future<void> _tryOpenRequestedEvent({
    String? initialEventId,
    bool preferPendingIntent = true,
  }) async {
    final intentController = GetIt.instance<EventOpenIntentController>();
    final pendingIntent = intentController.pendingIntent;
    final pendingEventId = _normalizeOptionalId(pendingIntent?.eventId);
    final normalizedInitialEventId = _normalizeOptionalId(initialEventId);
    final requestedEventId = preferPendingIntent
        ? (pendingEventId ?? normalizedInitialEventId)
        : (normalizedInitialEventId ?? pendingEventId);
    if (requestedEventId == null) {
      return;
    }
    if (pendingEventId == requestedEventId) {
      intentController.clear();
    }

    try {
      final event = await _eventUseCase.getEventById(requestedEventId);
      if (!mounted) {
        return;
      }

      final targetTeamId = _normalizeOptionalId(event.teamId);
      final shouldShowArchived = event.isArchived;
      final shouldRefresh =
          _selectedTeamId != targetTeamId ||
          _showArchived != shouldShowArchived;
      if (shouldRefresh) {
        setState(() {
          _selectedTeamId = targetTeamId;
          _showArchived = shouldShowArchived;
          _events = const <EventEntity>[];
          _archivedEvents = const <EventEntity>[];
        });
        await _refresh();
      } else if (shouldShowArchived) {
        await _loadArchivedIfNeeded(force: true);
      }

      if (!mounted) {
        return;
      }
      await _openEditor(event: event);
    } catch (error) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.eventLoadError(error));
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      if (_showArchived) {
        _loadingArchived = true;
      }
    });
    try {
      final active = await _eventUseCase.getEventsByTeam(_selectedTeamId);
      final archived = _showArchived
          ? await _eventUseCase.getArchivedEventsByTeam(_selectedTeamId)
          : _archivedEvents;
      if (!mounted) {
        return;
      }
      setState(() {
        _events = active;
        _archivedEvents = archived;
      });
    } catch (e) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.eventLoadError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingArchived = false;
        });
      }
    }
  }

  Future<void> _loadArchivedIfNeeded({bool force = false}) async {
    if (!force && _archivedEvents.isNotEmpty) {
      return;
    }
    setState(() {
      _loadingArchived = true;
    });
    try {
      final archived = await _eventUseCase.getArchivedEventsByTeam(
        _selectedTeamId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _archivedEvents = archived;
      });
    } catch (e) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.eventLoadArchivedError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingArchived = false;
        });
      }
    }
  }

  Future<void> _openEditor({EventEntity? event}) async {
    final loc = AppLocalizations.of(context)!;
    final rawTeamId = (event?.teamId ?? _selectedTeamId)?.trim();
    final teamId = (rawTeamId != null && rawTeamId.isNotEmpty)
        ? rawTeamId
        : null;

    final result = await showEventEditorDialog(
      context,
      initialTeamId: teamId,
      initialEvent: event,
      teamMembers: teamId != null
          ? (_teamMembersByTeamId[teamId] ?? const [])
          : const [],
    );
    if (result == null) {
      return;
    }

    try {
      if (event == null) {
        await _eventUseCase.createEvent(
          EventCreateRequestEntity(
            teamId: result.teamId,
            title: result.title,
            description: result.description,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
            allDay: result.allDay,
            location: result.location,
            participantUserIds: result.participantUserIds,
            participantDisplayNames: result.participantDisplayNames,
            createdByUserId: _actorUserId,
            createdByDisplayName: _actorDisplayName,
          ),
        );
        _showMessage(loc.eventCreateSuccess);
      } else {
        await _eventUseCase.updateEvent(
          event.id,
          EventUpdateRequestEntity(
            title: result.title,
            description: result.description,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
            clearEndsAt: result.endsAt == null,
            allDay: result.allDay,
            location: result.location,
            participantUserIds: result.participantUserIds,
            participantDisplayNames: result.participantDisplayNames,
          ),
        );
        _showMessage(loc.eventUpdateSuccess);
      }
      await _refresh();
    } catch (e) {
      _showMessage(loc.eventSaveError(e));
    }
  }

  Future<void> _toggleArchive(EventEntity event) async {
    final loc = AppLocalizations.of(context)!;
    try {
      if (event.isArchived) {
        await _eventUseCase.unarchiveEvent(event.id);
        _showMessage(loc.eventRestoreSuccess);
      } else {
        await _eventUseCase.archiveEvent(event.id);
        _showMessage(loc.eventArchiveSuccess);
      }
      await _refresh();
      if (_showArchived) {
        await _loadArchivedIfNeeded(force: true);
      }
    } catch (e) {
      _showMessage(loc.eventOperationFailedError(e));
    }
  }

  Future<void> _deleteArchived(EventEntity event) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await _eventUseCase.deleteEventPermanently(event.id);
      _showMessage(loc.eventDeletePermanentlySuccess);
      await _refresh();
      await _loadArchivedIfNeeded(force: true);
    } catch (e) {
      _showMessage(loc.eventDeleteError(e));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final teams = _teams;
    _ensureTeamAccessContextLoaded(teams);
    final manageableTeams = _manageableTeams;

    final selectedItems = _showArchived ? _archivedEvents : _events;
    final emptyStateTitle = _selectedTeamId == null
        ? loc.eventMyEventsEmptyTitle
        : (_showArchived
              ? loc.eventEmptyArchivedTitle
              : loc.eventEmptyActiveTitle);
    final emptyStateSubtitle = _selectedTeamId == null
        ? loc.eventMyEventsEmptySubtitle
        : (_showArchived
              ? loc.eventEmptyArchivedSubtitle
              : loc.eventEmptyActiveSubtitle);

    final header = EventWorkspaceHeader(
      embedded: widget.embedded,
      teams: manageableTeams,
      selectedTeamId: _selectedTeamId,
      showArchived: _showArchived,
      activeCount: _events.length,
      archivedCount: _archivedEvents.length,
      viewMode: _viewMode,
      onViewModeChanged: (value) => setState(() => _viewMode = value),
      onCreateEvent: () => _openEditor(),
      onTeamChanged: (value) async {
        setState(() {
          _selectedTeamId = value;
          _events = const <EventEntity>[];
          _archivedEvents = const <EventEntity>[];
        });
        await _refresh();
      },
      onArchivedToggle: (selected) async {
        setState(() {
          _showArchived = selected;
        });
        if (selected) {
          await _loadArchivedIfNeeded();
        }
      },
    );

    final loadingIndicator =
        (_loading || (_showArchived && _loadingArchived)) &&
            selectedItems.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        : null;

    final Widget content;
    if (_viewMode == EventViewMode.calendar) {
      // The calendar needs a bounded height for its own Expanded/scroll
      // internals to work, but the surrounding header can grow taller than
      // the viewport (long team names, wrapped chips, small phones) — so the
      // whole page scrolls instead of the calendar's fixed-height box ever
      // overflowing the page.
      final calendarHeight = (MediaQuery.sizeOf(context).height * 0.7).clamp(
        480.0,
        900.0,
      );
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 16),
            if (loadingIndicator != null)
              loadingIndicator
            else
              SizedBox(
                height: calendarHeight,
                child: EventCalendarView(
                  events: selectedItems,
                  weekStart: _calendarWeekStart,
                  onWeekStartChanged: (value) =>
                      setState(() => _calendarWeekStart = value),
                  onEventTap: (event) => _openEditor(event: event),
                  emptyStateTitle: emptyStateTitle,
                  emptyStateSubtitle: emptyStateSubtitle,
                ),
              ),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            header,
            const SizedBox(height: 16),
            if (loadingIndicator != null)
              loadingIndicator
            else if (selectedItems.isEmpty)
              EventEmptyState(
                title: emptyStateTitle,
                subtitle: emptyStateSubtitle,
              )
            else
              ...selectedItems.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EventListCard(
                    event: event,
                    onEdit: () => _openEditor(event: event),
                    onArchiveToggle: () => _toggleArchive(event),
                    onDeleteArchived: () => _deleteArchived(event),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return BlocListener<TeamMemberBloc, TeamMemberState>(
      bloc: _teamMemberBloc,
      listener: (context, state) {
        if (state is TeamMembersLoaded) {
          final teamId =
              state.teamId ??
              (state.members.isNotEmpty ? state.members.first.teamId : null);
          if (teamId != null) {
            _loadingTeamMemberIds.remove(teamId);
            setState(() {
              _teamMembersByTeamId[teamId] = state.members
                  .map((member) => TeamMemberforView(teamMember: member))
                  .toList();
            });
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
      child: SafeArea(
        top: !widget.embedded,
        bottom: widget.embedded,
        child: content,
      ),
    );
  }
}
