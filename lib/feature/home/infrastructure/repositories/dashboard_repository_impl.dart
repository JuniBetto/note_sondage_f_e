import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_remote/clocking_remote_data_source.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_remote/sondage_remote_data_source.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required TeamRemoteDataSource teamRemote,
    required SondageRemoteDataSource sondageRemote,
    required ClockingRemoteDataSource clockingRemote,
    required ShiftRemoteDataSource shiftRemote,
  }) : _teamRemote = teamRemote,
       _sondageRemote = sondageRemote,
       _clockingRemote = clockingRemote,
       _shiftRemote = shiftRemote;

  final TeamRemoteDataSource _teamRemote;
  final SondageRemoteDataSource _sondageRemote;
  final ClockingRemoteDataSource _clockingRemote;
  final ShiftRemoteDataSource _shiftRemote;
  _DashboardSnapshot? _lastSnapshot;
  DateTime? _lastSnapshotAt;
  Future<_DashboardSnapshot>? _snapshotFuture;

  @override
  Future<DashboardStats> getStats() async {
    final snapshot = await _getSnapshot();
    final teams = snapshot.teams;
    final sondages = snapshot.sondages;
    final todayClocking = snapshot.todayClocking;
    final todayShifts = snapshot.todayShifts;
    final totalMembers = teams.fold<int>(
      0,
      (sum, team) => sum + team.memberCount,
    );

    final activeSurveys = sondages
        .where((s) => s.status == SondageStatus.active)
        .length;

    return DashboardStats(
      activeTeams: teams.length,
      totalMembers: totalMembers,
      activeSurveys: activeSurveys,
      todayClocking: todayClocking.length,
      todayShifts: todayShifts.length,
    );
  }

  @override
  Future<List<RecentActivity>> getRecentActivities() async {
    final now = DateTime.now();
    final snapshot = await _getSnapshot();
    final teams = snapshot.teams;
    final clockings = snapshot.todayClocking;
    final shifts = snapshot.todayShifts;
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

    // Shift activities
    for (final s in shifts) {
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

    // Sort by most recent first, keep top 10
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(10).toList();
  }

  String _padTime(int v) => v.toString().padLeft(2, '0');

  Future<_DashboardSnapshot> _getSnapshot() {
    final now = DateTime.now();
    if (_lastSnapshot != null &&
        _lastSnapshotAt != null &&
        now.difference(_lastSnapshotAt!) < const Duration(seconds: 20)) {
      return Future<_DashboardSnapshot>.value(_lastSnapshot!);
    }
    if (_snapshotFuture != null) {
      return _snapshotFuture!;
    }
    _snapshotFuture = _loadSnapshot()
        .then((snapshot) {
          _lastSnapshot = snapshot;
          _lastSnapshotAt = DateTime.now();
          return snapshot;
        })
        .whenComplete(() {
          _snapshotFuture = null;
        });
    return _snapshotFuture!;
  }

  Future<_DashboardSnapshot> _loadSnapshot() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = await Future.wait([
      _teamRemote.getAll().catchError((_) => <TeamEntity>[]),
      _sondageRemote.getAll().catchError((_) => <SondageEntity>[]),
      _clockingRemote
          .getByDate(now)
          .catchError((_) => <ClockingRecordEntity>[]),
      _shiftRemote
          .getAssignments(
            from: today,
            to: DateTime(today.year, today.month, today.day, 23, 59, 59),
          )
          .catchError((_) => <ShiftAssignmentEntity>[]),
    ]);

    return _DashboardSnapshot(
      teams: results[0] as List<TeamEntity>,
      sondages: results[1] as List<SondageEntity>,
      todayClocking: results[2] as List<ClockingRecordEntity>,
      todayShifts: results[3] as List<ShiftAssignmentEntity>,
    );
  }
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.teams,
    required this.sondages,
    required this.todayClocking,
    required this.todayShifts,
  });

  final List<TeamEntity> teams;
  final List<SondageEntity> sondages;
  final List<ClockingRecordEntity> todayClocking;
  final List<ShiftAssignmentEntity> todayShifts;
}
