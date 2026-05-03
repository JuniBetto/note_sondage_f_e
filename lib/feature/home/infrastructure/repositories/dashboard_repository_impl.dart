import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_remote/clocking_remote_data_source.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_remote/sondage_remote_data_source.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_member_remote_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required TeamRemoteDataSource teamRemote,
    required TeamMemberRemoteDataSource teamMemberRemote,
    required SondageRemoteDataSource sondageRemote,
    required ClockingRemoteDataSource clockingRemote,
    required ShiftRemoteDataSource shiftRemote,
  })  : _teamRemote = teamRemote,
        _teamMemberRemote = teamMemberRemote,
        _sondageRemote = sondageRemote,
        _clockingRemote = clockingRemote,
        _shiftRemote = shiftRemote;

  final TeamRemoteDataSource _teamRemote;
  final TeamMemberRemoteDataSource _teamMemberRemote;
  final SondageRemoteDataSource _sondageRemote;
  final ClockingRemoteDataSource _clockingRemote;
  final ShiftRemoteDataSource _shiftRemote;

  @override
  Future<DashboardStats> getStats() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _teamRemote.getAll().then<List<TeamEntity>>((v) => v).catchError((_) => <TeamEntity>[]),
      _sondageRemote.getAll().then<List<SondageEntity>>((v) => v).catchError((_) => <SondageEntity>[]),
      _clockingRemote.getByDate(now).then<List<ClockingRecordEntity>>((v) => v).catchError((_) => <ClockingRecordEntity>[]),
      _shiftRemote.getAssignments(from: DateTime(now.year, now.month, now.day), to: DateTime(now.year, now.month, now.day, 23, 59, 59))
          .then<List<ShiftAssignmentEntity>>((v) => v).catchError((_) => <ShiftAssignmentEntity>[]),
    ]);

    final teams = results[0] as List<TeamEntity>;
    final sondages = results[1] as List<SondageEntity>;
    final todayClocking = results[2] as List<ClockingRecordEntity>;
    final todayShifts = results[3] as List<ShiftAssignmentEntity>;

    // Conta i membri di tutti i team in parallelo
    int totalMembers = 0;
    if (teams.isNotEmpty) {
      final memberCounts = await Future.wait(
        teams.map(
          (t) => (t.id == null)
              ? Future<int>.value(0)
              : _teamMemberRemote
                  .getAllByTeamId(t.id!)
                  .then((m) => m.length)
                  .catchError((_) => 0),
        ),
      );
      totalMembers = memberCounts.fold(0, (sum, c) => sum + c);
    }

    final activeSurveys =
        sondages.where((s) => s.status == SondageStatus.active).length;

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
    final today = DateTime(now.year, now.month, now.day);

    final results = await Future.wait([
      _teamRemote.getAll().catchError((_) => <TeamEntity>[]),
      _clockingRemote.getByDate(now).catchError((_) => <ClockingRecordEntity>[]),
      _shiftRemote.getAssignments(from: today, to: DateTime(today.year, today.month, today.day, 23, 59, 59))
          .catchError((_) => <ShiftAssignmentEntity>[]),
      _sondageRemote.getAll().catchError((_) => <SondageEntity>[]),
    ]);

    final teams = results[0] as List<TeamEntity>;
    final clockings = results[1] as List<ClockingRecordEntity>;
    final shifts = results[2] as List<ShiftAssignmentEntity>;
    final sondages = results[3] as List<SondageEntity>;

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
        activities.add(RecentActivity(
          id: '${r.id}_out',
          title: 'Clock-out — ${r.userName}',
          subtitle: r.teamName.isNotEmpty ? r.teamName : '',
          type: RecentActivityType.clockOut,
          timestamp: r.clockOutTime!,
        ));
      }
      activities.add(RecentActivity(
        id: '${r.id}_in',
        title: 'Clock-in — ${r.userName}',
        subtitle: r.teamName.isNotEmpty ? r.teamName : '',
        type: RecentActivityType.clockIn,
        timestamp: r.clockInTime ?? r.date,
      ));
    }

    // Shift activities
    for (final s in shifts) {
      activities.add(RecentActivity(
        id: 'shift_${s.id}',
        title: s.profileName != null ? 'Shift — ${s.profileName}' : 'Shift assigned',
        subtitle: '${_padTime(s.startTime.hour)}:${_padTime(s.startTime.minute)} → ${_padTime(s.endTime.hour)}:${_padTime(s.endTime.minute)}${s.overnight ? ' (+1)' : ''}',
        type: RecentActivityType.shiftAssigned,
        timestamp: DateTime(s.shiftDate.year, s.shiftDate.month, s.shiftDate.day, s.startTime.hour, s.startTime.minute),
      ));
    }

    // Sondage activities (today or recent)
    for (final s in sondages) {
      if (s.status == SondageStatus.active) {
        activities.add(RecentActivity(
          id: 'sondage_${s.id}',
          title: s.name.isNotEmpty ? s.name : 'Survey',
          subtitle: 'Active survey',
          type: RecentActivityType.sondageCreated,
          timestamp: now.subtract(const Duration(hours: 1)),
        ));
      }
    }

    // Sort by most recent first, keep top 10
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(10).toList();
  }

  String _padTime(int v) => v.toString().padLeft(2, '0');
}
