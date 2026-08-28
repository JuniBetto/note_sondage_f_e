import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_remote/clocking_remote_data_source.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/infrastructure/data_source/event_remote_data_source.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_remote/sondage_remote_data_source.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/infrastructure/data_source/task_remote_data_source.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required TeamRemoteDataSource teamRemote,
    required SondageRemoteDataSource sondageRemote,
    required ClockingRemoteDataSource clockingRemote,
    required ShiftRemoteDataSource shiftRemote,
    required TaskRemoteDataSource taskRemote,
    required ChatRemoteDataSource chatRemote,
    required EventRemoteDataSource eventRemote,
    required String Function() currentUserIdProvider,
  }) : _teamRemote = teamRemote,
       _sondageRemote = sondageRemote,
       _clockingRemote = clockingRemote,
       _shiftRemote = shiftRemote,
       _taskRemote = taskRemote,
       _chatRemote = chatRemote,
       _eventRemote = eventRemote,
       _currentUserIdProvider = currentUserIdProvider;

  final TeamRemoteDataSource _teamRemote;
  final SondageRemoteDataSource _sondageRemote;
  final ClockingRemoteDataSource _clockingRemote;
  final ShiftRemoteDataSource _shiftRemote;
  final TaskRemoteDataSource _taskRemote;
  final ChatRemoteDataSource _chatRemote;
  final EventRemoteDataSource _eventRemote;
  final String Function() _currentUserIdProvider;
  Future<_DashboardSnapshot>? _snapshotFuture;

  @override
  Future<DashboardStats> getStats() async {
    final snapshot = await _getSnapshot();
    final teams = snapshot.teams;
    final todayClocking = snapshot.todayClocking;
    final myShifts = snapshot.myShifts;
    final totalMembers = teams.fold<int>(
      0,
      (sum, team) => sum + team.memberCount,
    );
    final myOpenTasks = snapshot.myTasks
        .where(
          (task) =>
              task.status != TaskStatus.done &&
              task.status != TaskStatus.canceled,
        )
        .length;
    final unreadChatMessages = snapshot.chatEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value.unreadCount,
    );
    final myEvents = snapshot.myEvents
        .where((event) => !event.isArchived)
        .length;

    return DashboardStats(
      activeTeams: teams.length,
      totalMembers: totalMembers,
      activeSurveys: snapshot.activeSurveyCount,
      todayClocking: todayClocking.length,
      todayShifts: myShifts.length,
      myOpenTasks: myOpenTasks,
      unreadChatMessages: unreadChatMessages,
      myEvents: myEvents,
    );
  }

  @override
  Future<List<RecentActivity>> getRecentActivities() async {
    final now = DateTime.now();
    final snapshot = await _getSnapshot();
    final teams = snapshot.teams;
    final clockings = snapshot.todayClocking;
    final shifts = snapshot.myShifts;
    final sondages = snapshot.sondages;

    final activities = <RecentActivity>[];

    for (final team in teams) {
      if (team.id == null || team.id!.isEmpty) continue;
      activities.add(
        RecentActivity(
          id: 'team_${team.id}',
          title: team.name.isNotEmpty
              ? 'Team created — ${team.name}'
              : 'Team created',
          subtitle: team.description.isNotEmpty ? team.description : 'New team',
          type: RecentActivityType.teamCreated,
          timestamp: team.createdAt,
        ),
      );
    }

    // Clocking activities
    for (final r in clockings) {
      if (r.clockOutTime != null) {
        activities.add(
          RecentActivity(
            id: '${r.id}_out',
            title: 'Clock-out — ${r.userName}',
            subtitle: r.teamName.isNotEmpty ? r.teamName : '',
            type: RecentActivityType.clockOut,
            timestamp: r.clockOutTime!,
          ),
        );
      }
      activities.add(
        RecentActivity(
          id: '${r.id}_in',
          title: 'Clock-in — ${r.userName}',
          subtitle: r.teamName.isNotEmpty ? r.teamName : '',
          type: RecentActivityType.clockIn,
          timestamp: r.clockInTime ?? r.date,
        ),
      );
    }

    // Shift activities (only today's, so the feed reflects genuinely recent
    // activity instead of being flooded by the whole month's assignments)
    final todayShifts = shifts.where(
      (s) =>
          s.shiftDate.year == now.year &&
          s.shiftDate.month == now.month &&
          s.shiftDate.day == now.day,
    );
    for (final s in todayShifts) {
      activities.add(
        RecentActivity(
          id: 'shift_${s.id}',
          title: s.profileName != null
              ? 'Shift — ${s.profileName}'
              : 'Shift assigned',
          subtitle:
              '${_padTime(s.startTime.hour)}:${_padTime(s.startTime.minute)} → ${_padTime(s.endTime.hour)}:${_padTime(s.endTime.minute)}${s.overnight ? ' (+1)' : ''}',
          type: RecentActivityType.shiftAssigned,
          timestamp: DateTime(
            s.shiftDate.year,
            s.shiftDate.month,
            s.shiftDate.day,
            s.startTime.hour,
            s.startTime.minute,
          ),
        ),
      );
    }

    // Sondage activities (today or recent)
    for (final s in sondages) {
      if (s.status == SondageStatus.active) {
        activities.add(
          RecentActivity(
            id: 'sondage_${s.id}',
            title: s.name.isNotEmpty ? s.name : 'Survey',
            subtitle: 'Active survey',
            type: RecentActivityType.sondageCreated,
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        );
      }
    }

    // Task activities (my open tasks)
    for (final task in snapshot.myTasks) {
      if (task.status == TaskStatus.done ||
          task.status == TaskStatus.canceled) {
        continue;
      }
      activities.add(
        RecentActivity(
          id: 'task_${task.id}',
          title: task.title.isNotEmpty ? task.title : 'Task',
          subtitle: task.teamId == null ? 'Personal task' : 'Team task',
          type: RecentActivityType.taskAssigned,
          timestamp: task.updatedAt,
        ),
      );
    }

    // Chat activities (last message per team conversation)
    for (final entry in snapshot.chatEntries) {
      final summary = entry.value;
      if (summary.lastMessageAt == null || !summary.hasUnread) continue;
      activities.add(
        RecentActivity(
          id: 'chat_${summary.conversationId}',
          title: 'Chat — ${entry.key.name}',
          subtitle: summary.lastMessagePreview,
          type: RecentActivityType.chatMessage,
          timestamp: summary.lastMessageAt!,
        ),
      );
    }

    // Sort by most recent first, keep top 12
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(12).toList();
  }

  String _padTime(int v) => v.toString().padLeft(2, '0');

  Future<_DashboardSnapshot> _getSnapshot() {
    if (_snapshotFuture != null) {
      return _snapshotFuture!;
    }
    _snapshotFuture = _loadSnapshot().then((snapshot) => snapshot).whenComplete(
      () {
        _snapshotFuture = null;
      },
    );
    return _snapshotFuture!;
  }

  Future<_DashboardSnapshot> _loadSnapshot() async {
    final now = DateTime.now();
    //final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final currentUserId = _currentUserIdProvider().trim();
    final results = await Future.wait([
      _teamRemote.getDashboardSummaries().catchError(
        (_) => <Map<String, dynamic>>[],
      ),
      _sondageRemote.getAll().catchError((_) => <SondageEntity>[]),
      _clockingRemote
          .getByDate(now)
          .catchError((_) => <ClockingRecordEntity>[]),
      _shiftRemote
          .getAssignments(
            from: monthStart,
            to: monthEnd,
            visibleUserIds: currentUserId.isEmpty ? null : [currentUserId],
          )
          .catchError((_) => <ShiftAssignmentEntity>[]),
      _taskRemote.getMyTasks().catchError((_) => <TaskEntity>[]),
    ]);

    final dashboardSummaries = results[0] as List<Map<String, dynamic>>;
    final teams = dashboardSummaries
        .map((entry) => entry['team'])
        .whereType<Map>()
        .map(
          (entry) => TeamMapper.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
    final activeSurveyCount = dashboardSummaries.fold<int>(0, (sum, entry) {
      final activeSondaggi = entry['activeSondaggi'];
      if (activeSondaggi is List) {
        return sum + activeSondaggi.length;
      }
      return sum;
    });

    final chatEntriesFuture = Future.wait(
      teams.map(_loadChatSummary),
    ).then(
      (entries) => entries
          .whereType<MapEntry<TeamEntity, ChatTeamConversationSummaryEntity>>()
          .toList(),
    );
    final myEventsFuture = _loadMyEvents(teams, monthStart, monthEnd);

    return _DashboardSnapshot(
      teams: teams,
      sondages: results[1] as List<SondageEntity>,
      todayClocking: results[2] as List<ClockingRecordEntity>,
      myShifts: results[3] as List<ShiftAssignmentEntity>,
      myTasks: results[4] as List<TaskEntity>,
      chatEntries: await chatEntriesFuture,
      activeSurveyCount: activeSurveyCount,
      myEvents: await myEventsFuture,
    );
  }

  Future<MapEntry<TeamEntity, ChatTeamConversationSummaryEntity>?>
  _loadChatSummary(TeamEntity team) async {
    final teamId = team.id?.trim();
    if (teamId == null || teamId.isEmpty) return null;
    try {
      final summary = await _chatRemote.getTeamConversationSummary(teamId);
      return MapEntry(team, summary);
    } catch (_) {
      return null;
    }
  }

  /// Events for the user's teams plus personal (team-less) events, limited
  /// to the current month — mirrors the [_shiftRemote] "my shifts" window.
  Future<List<EventEntity>> _loadMyEvents(
    List<TeamEntity> teams,
    DateTime from,
    DateTime to,
  ) async {
    final teamIds = teams
        .map((team) => team.id?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final results = await Future.wait([
      _eventRemote.getEventsByTeam(null).catchError((_) => <EventEntity>[]),
      ...teamIds.map(
        (teamId) => _eventRemote
            .getEventsByTeam(teamId)
            .catchError((_) => <EventEntity>[]),
      ),
    ]);
    return results
        .expand((events) => events)
        .where(
          (event) =>
              !event.startsAt.isBefore(from) && !event.startsAt.isAfter(to),
        )
        .toList();
  }
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.teams,
    required this.sondages,
    required this.todayClocking,
    required this.myShifts,
    required this.myTasks,
    required this.chatEntries,
    required this.activeSurveyCount,
    required this.myEvents,
  });

  final List<TeamEntity> teams;
  final List<SondageEntity> sondages;
  final List<ClockingRecordEntity> todayClocking;
  final List<ShiftAssignmentEntity> myShifts;
  final List<TaskEntity> myTasks;
  final List<MapEntry<TeamEntity, ChatTeamConversationSummaryEntity>>
  chatEntries;
  final int activeSurveyCount;
  final List<EventEntity> myEvents;
}
