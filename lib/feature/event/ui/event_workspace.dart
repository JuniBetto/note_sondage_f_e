import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/event/domain/entities/event_create_request_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/domain/entities/event_update_request_entity.dart';
import 'package:note_sondage/feature/event/navigation/event_open_intent_controller.dart';
import 'package:note_sondage/feature/event/domain/entities/event_reminder_anchor.dart';
import 'package:note_sondage/feature/event/domain/entities/event_text_size.dart';
import 'package:note_sondage/feature/event/domain/use_case/event_use_case.dart';
import 'package:note_sondage/feature/event/notification/event_alarm_scheduler.dart';
import 'package:note_sondage/feature/event/ui/event_density_scope.dart';
import 'package:note_sondage/feature/event/ui/event_text_size_cubit.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_calendar_view.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_detail_dialog.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_editor_dialog.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_empty_state.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_list_card.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_reminder_labels.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_workspace_header.dart';
import 'package:note_sondage/feature/notification/realtime/event_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_reminder_offset_editor.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_confirmation_dialog.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/scroll_overflow_hint.dart';

enum EventViewMode { card, calendar }

class EventWorkspace extends StatefulWidget {
  const EventWorkspace({
    super.key,
    this.initialTeamId,
    this.initialEventId,
    this.embedded = false,
    this.isActive = true,
    this.isTabTransitioning = false,
  });

  final String? initialTeamId;
  final String? initialEventId;
  final bool embedded;

  /// Whether this page is currently the one the user is actually looking
  /// at. Both the web `IndexedStack` and the mobile tab bar that can host
  /// this widget mount it eagerly, well before it becomes visible, so the
  /// auto-tutorial must not fire (and mark itself as "seen") until this is
  /// true — otherwise it would silently show a tutorial for a page nobody
  /// is looking at and never offer it again.
  final bool isActive;

  /// Whether the parent tab controller (mobile only) is still animating
  /// between tabs. The auto-tutorial waits for the swipe to fully settle,
  /// otherwise it races with the tab-change listener that dismisses any
  /// active showcase and gets killed moments after starting.
  final bool isTabTransitioning;

  @override
  State<EventWorkspace> createState() => _EventWorkspaceState();
}

class _EventWorkspaceState extends State<EventWorkspace> {
  final EventUseCase _eventUseCase = GetIt.instance<EventUseCase>();
  final TeamMemberBloc _teamMemberBloc = GetIt.instance<TeamMemberBloc>();
  final RoleUseCase _roleUseCase = GetIt.instance<RoleUseCase>();
  final EventAlarmScheduler _eventAlarmScheduler =
      GetIt.instance<EventAlarmScheduler>();
  // Lets the user shrink/grow all text in the compact/mobile layout to fit
  // more content on screen (see EventTextSizeToggle in EventWorkspaceHeader).
  final EventTextSizeCubit _eventTextSizeCubit =
      GetIt.instance<EventTextSizeCubit>();

  final UserArchiveService _archiveService =
      GetIt.instance<UserArchiveService>();

  /// `null` means "My Events" — the caller's own events across every team,
  /// mirroring Shift's model rather than a single always-selected team.
  String? _selectedTeamId;

  /// Every event visible to the caller (server no longer distinguishes
  /// archived here — see [_locallyArchivedEventIds]).
  List<EventEntity> _events = const <EventEntity>[];

  /// Which events *this device's user* has archived. Unlike a team-managed
  /// edit/delete, archiving an event is purely personal — like team, survey
  /// and shift archiving elsewhere in the app — so it never touches the
  /// server and needs no permission: it only hides the event from your own
  /// view, never from teammates.
  Set<String> _locallyArchivedEventIds = const <String>{};
  List<EventEntity> get _activeEvents => _events
      .where((event) => !_locallyArchivedEventIds.contains(event.id))
      .toList(growable: false);
  List<EventEntity> get _archivedEvents => _events
      .where((event) => _locallyArchivedEventIds.contains(event.id))
      .toList(growable: false);

  bool _loading = false;
  bool _showArchived = false;
  EventViewMode _viewMode = EventViewMode.card;
  DateTime _calendarWeekStart = mondayOfWeek(DateTime.now());
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  final GlobalKey _createButtonKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  bool _tutorialScheduled = false;
  String get _tutorialId => kIsWeb ? 'web-events' : 'mobile-events';

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
  }

  List<TeamEntity> get _teams {
    // Also read by tap/dialog callbacks, where subscribing is not allowed.
    final state = context.read<TeamBloc>().state;
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

  /// Setting your own reminder doesn't need "manage team" rights — only
  /// being the creator or one of the participants, the only people an event
  /// reminder could plausibly belong to. Mirrors Task's `_canSetMyReminder`.
  bool _canSetMyReminder(EventEntity event) =>
      event.createdByUserId.trim() == _currentUid ||
      event.participantUserIds.any((id) => id.trim() == _currentUid);

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

  /// Mirrors the backend rule ("Solo owner, admin o ruoli con permessi
  /// Admin/Manage possono gestire gli eventi del team") so the edit action
  /// is hidden instead of failing with a 400 once the user taps it. A
  /// personal event (no team) is editable only by whoever created it.
  bool _canEditEvent(EventEntity event) {
    final teamId = event.teamId?.trim();
    if (teamId == null || teamId.isEmpty) {
      return event.createdByUserId.trim() == _currentUid;
    }
    final team = _teams
        .where((candidate) => candidate.id?.trim() == teamId)
        .firstOrNull;
    if (team == null) {
      return false;
    }
    return _canManageTeam(team);
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
      final shouldShowArchived = _locallyArchivedEventIds.contains(event.id);
      final shouldRefresh =
          _selectedTeamId != targetTeamId ||
          _showArchived != shouldShowArchived;
      if (shouldRefresh) {
        setState(() {
          _selectedTeamId = targetTeamId;
          _showArchived = shouldShowArchived;
          _events = const <EventEntity>[];
        });
        await _refresh();
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
    });
    try {
      final events = await _eventUseCase.getEventsByTeam(_selectedTeamId);
      final archivedIds = await _archiveService.loadArchivedIds(
        userId: _currentUid,
        bucket: ArchiveBuckets.events,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _events = events;
        _locallyArchivedEventIds = archivedIds;
      });
      unawaited(_eventAlarmScheduler.syncEvents(_events));
    } catch (e) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.eventLoadError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
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
            reminderOffsets: result.reminderOffsets,
            reminderAnchor: result.reminderAnchor,
          ),
        );
        if (!mounted) return;
        AppSnackBar.showSuccessOverlay(context, loc.eventCreateSuccess);
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
            reminderOffsets: result.reminderOffsets,
            reminderAnchor: result.reminderAnchor,
          ),
        );
        if (!mounted) return;
        AppSnackBar.showSuccessOverlay(context, loc.eventUpdateSuccess);
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showMessage(loc.eventSaveError(e));
    }
  }

  /// Lets the creator OR any participant set their own independent reminder
  /// on [event] — unlike [_openEditor], this needs no "manage team"
  /// permission, only being one of those people (see [_canSetMyReminder]).
  /// There's no `EventBloc` (see [EventAlarmScheduler]'s doc comment), so
  /// this calls [EventUseCase.updateMyReminder] directly and re-syncs the
  /// scheduler itself instead of relying on a bloc event.
  Future<void> _openMyReminderSheet(EventEntity event) async {
    List<int> offsets = List<int>.from(event.reminderOffsets);
    EventReminderAnchor anchor = event.reminderAnchor;
    final hasAnchorDate = event.reminderAnchorTime != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setModalState) {
              final theme = Theme.of(sheetContext);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      eventMyReminderSheetTitle(sheetContext),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      eventMyReminderSheetSubtitle(sheetContext),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!hasAnchorDate)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          eventMyReminderNoAnchorHint(sheetContext),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    TaskReminderOffsetEditor(
                      offsets: offsets,
                      onChanged: (updated) =>
                          setModalState(() => offsets = updated),
                    ),
                    if (offsets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SegmentedButton<EventReminderAnchor>(
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: theme.textTheme.labelSmall,
                        ),
                        selected: {anchor},
                        segments: [
                          ButtonSegment(
                            value: EventReminderAnchor.startsAt,
                            label: Text(
                              eventReminderAnchorStartsAtLabel(sheetContext),
                            ),
                          ),
                          ButtonSegment(
                            value: EventReminderAnchor.endsAt,
                            label: Text(
                              eventReminderAnchorEndsAtLabel(sheetContext),
                            ),
                          ),
                        ],
                        onSelectionChanged: (selection) =>
                            setModalState(() => anchor = selection.first),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomAppButton(
                      isLoading: saving,
                      isActive: true,
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                final updated = await _eventUseCase
                                    .updateMyReminder(
                                      event.id,
                                      offsets,
                                      anchor,
                                    );
                                unawaited(
                                  _eventAlarmScheduler.syncEvents([
                                    ..._events.where((e) => e.id != event.id),
                                    updated,
                                  ]),
                                );
                                if (!sheetContext.mounted) {
                                  return;
                                }
                                Navigator.of(sheetContext).pop();
                              } catch (_) {
                                setModalState(() => saving = false);
                                if (!sheetContext.mounted) {
                                  return;
                                }
                                AppSnackBar.showError(
                                  sheetContext,
                                  eventMyReminderSaveError(sheetContext),
                                );
                              }
                            },
                      leadingIcon: const Icon(Icons.check_rounded, size: 18),
                      child: Text(eventMyReminderSaveAction(sheetContext)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    await _refresh();
  }

  /// Purely local and personal — like archiving a team, a survey or a shift
  /// elsewhere in the app, this never touches the server and needs no
  /// management permission. It only hides the event from *your* view;
  /// teammates keep seeing it exactly as before.
  Future<void> _toggleArchive(EventEntity event) async {
    final loc = AppLocalizations.of(context)!;
    final wasArchivedForMe = _locallyArchivedEventIds.contains(event.id);
    await _archiveService.setArchived(
      userId: _currentUid,
      bucket: ArchiveBuckets.events,
      itemId: event.id,
      archived: !wasArchivedForMe,
    );
    if (!mounted) return;
    setState(() {
      _locallyArchivedEventIds = wasArchivedForMe
          ? ({..._locallyArchivedEventIds}..remove(event.id))
          : {..._locallyArchivedEventIds, event.id};
    });
    AppSnackBar.showSuccessOverlay(
      context,
      wasArchivedForMe ? loc.eventRestoreSuccess : loc.eventArchiveSuccess,
    );
  }

  Future<void> _deleteArchived(EventEntity event) async {
    final loc = AppLocalizations.of(context)!;
    // This is a permanent, unrecoverable delete — unlike every other delete
    // flow in the app (team/sondage/task/shift) it had no confirmation step
    // at all before this.
    final confirmed = await showAppConfirmationDialog(
      context,
      title: loc.deleteEventTitle,
      message: loc.deleteEventMessage,
      confirmLabel: loc.eventDeleteAction,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _eventUseCase.deleteEventPermanently(event.id);
      if (!mounted) return;
      AppSnackBar.showSuccessOverlay(
        context,
        loc.eventDeletePermanentlySuccess,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showMessage(loc.eventDeleteError(e));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _registerTutorials(BuildContext context) {
    AppTutorialController.registerTargets(
      tutorialId: _tutorialId,
      keys: <GlobalKey>[_createButtonKey, _filterKey, _listKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: _tutorialId,
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_createButtonKey, _filterKey, _listKey],
      ),
    );
    if (kIsWeb) {
      AppTutorialController.registerReplayAction(
        tutorialId: 'web-main-8',
        action: () => AppTutorialController.replayRegistered(
          context: context,
          tutorialId: _tutorialId,
        ),
      );
    }
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
      if (!widget.isActive || widget.isTabTransitioning) {
        _tutorialScheduled = false;
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: _tutorialId,
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_createButtonKey, _filterKey, _listKey],
      );
    });
  }

  Widget _buildShowcase({
    required GlobalKey showcaseKey,
    required String title,
    required String description,
    required Widget child,
  }) {
    if (isInspectorSelectionActive) {
      return child;
    }
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      child: child,
    );
  }

  String _filterTitle(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialEventFilterTitle;
  }

  String _filterDescription(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialEventFilterDescription;
  }

  String _listTitle(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialEventListTitle;
  }

  String _listDescription(BuildContext context) {
    return AppLocalizations.of(context)!.tutorialEventListDescription;
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe during build so team/permission changes still refresh the UI.
    context.watch<TeamBloc>();
    final loc = AppLocalizations.of(context)!;
    final teams = _teams;
    _ensureTeamAccessContextLoaded(teams);
    final manageableTeams = _manageableTeams;

    final selectedItems = _showArchived ? _archivedEvents : _activeEvents;
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
      activeCount: _activeEvents.length,
      archivedCount: _archivedEvents.length,
      viewMode: _viewMode,
      onViewModeChanged: (value) => setState(() => _viewMode = value),
      onCreateEvent: () => _openEditor(),
      onTeamChanged: (value) async {
        setState(() {
          _selectedTeamId = value;
          _events = const <EventEntity>[];
        });
        await _refresh();
      },
      onArchivedToggle: (selected) {
        setState(() {
          _showArchived = selected;
        });
      },
      createButtonKey: _createButtonKey,
      createButtonTitle: AppLocalizations.of(context)!.tutorialEventCreateTitle,
      createButtonDescription: AppLocalizations.of(
        context,
      )!.tutorialEventCreateDescription,
      filterKey: _filterKey,
      filterTitle: _filterTitle(context),
      filterDescription: _filterDescription(context),
    );

    final loadingIndicator = _loading && selectedItems.isEmpty
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
      final calendarSection =
          loadingIndicator ??
          SizedBox(
            height: calendarHeight,
            child: EventCalendarView(
              events: selectedItems,
              weekStart: _calendarWeekStart,
              onWeekStartChanged: (value) =>
                  setState(() => _calendarWeekStart = value),
              onEventTap: (event) => showEventDetailDialog(
                context,
                event: event,
                canEdit: _canEditEvent(event),
                onEdit: () => _openEditor(event: event),
                canSetMyReminder: _canSetMyReminder(event),
                onSetMyReminder: () => _openMyReminderSheet(event),
              ),
              emptyStateTitle: emptyStateTitle,
              emptyStateSubtitle: emptyStateSubtitle,
            ),
          );
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 16),
            _buildShowcase(
              showcaseKey: _listKey,
              title: _listTitle(context),
              description: _listDescription(context),
              child: calendarSection,
            ),
          ],
        ),
      );
    } else {
      final itemsSection =
          loadingIndicator ??
          (selectedItems.isEmpty
              ? EventEmptyState(
                  title: emptyStateTitle,
                  subtitle: emptyStateSubtitle,
                )
              : Column(
                  children: [
                    for (final event in selectedItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EventListCard(
                          event: event,
                          isArchivedForMe: _locallyArchivedEventIds.contains(
                            event.id,
                          ),
                          canEdit: _canEditEvent(event),
                          onEdit: () => _openEditor(event: event),
                          onArchiveToggle: () => _toggleArchive(event),
                          onDeleteArchived: () => _deleteArchived(event),
                          canSetMyReminder: _canSetMyReminder(event),
                          onSetMyReminder: () => _openMyReminderSheet(event),
                        ),
                      ),
                  ],
                ));
      content = ScrollOverflowHint(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              header,
              const SizedBox(height: 16),
              _buildShowcase(
                showcaseKey: _listKey,
                title: _listTitle(context),
                description: _listDescription(context),
                child: itemsSection,
              ),
            ],
          ),
        ),
      );
    }

    _registerTutorials(context);
    if (widget.isActive && !widget.isTabTransitioning) {
      _scheduleTutorial();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 760) {
              // Wide/desktop layout has enough room that shrinking/growing
              // text to fit more content isn't the point.
              return content;
            }
            return BlocBuilder<EventTextSizeCubit, EventTextSize>(
              bloc: _eventTextSizeCubit,
              builder: (context, textSize) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textSize.scaleFactor),
                  ),
                  child: EventDensityScope(
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
