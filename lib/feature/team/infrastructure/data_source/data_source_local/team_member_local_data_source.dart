import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_planning_constraints_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/team_member_hive_model.dart';

class TeamMemberLocalDataSource {
  static const String _boxName = 'team_members_box';

  Future<Box<TeamMemberHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<TeamMemberHiveModel>(_boxName);
    }
    return await Hive.openBox<TeamMemberHiveModel>(_boxName);
  }

  Future<void> saveAll(List<TeamMemberEntity> members) async {
    final box = await _openBox();
    await box.clear();
    final models = members.map(
      (e) => TeamMemberHiveModel(
        id: e.id,
        userId: e.userId,
        userEmail: e.userEmail,
        teamId: e.teamId,
        status: e.status.value,
        roleId: e.roleId,
        imageUrl: e.imageUrl,
        fileName: e.fileName,
        initialName: e.initialName,
        planningConstraintsJson: _encodePlanningConstraints(
          e.planningConstraints,
        ),
      ),
    );
    await box.addAll(models);
  }

  Future<List<TeamMemberEntity>> getAll() async {
    final box = await _openBox();
    return box.values.map(_fromModel).toList();
  }

  /// Legge i membri filtrati per teamId.
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    final all = await getAll();
    return all.where((m) => m.teamId == teamId).toList();
  }

  Future<void> removeByTeamId(String teamId) async {
    final all = await getAll();
    await saveAll(all.where((member) => member.teamId != teamId).toList());
  }

  TeamMemberEntity _fromModel(TeamMemberHiveModel m) {
    return TeamMemberEntity(
      id: m.id,
      userId: m.userId,
      userEmail: m.userEmail,
      teamId: m.teamId,
      status: UserStatus.values.firstWhere(
        (s) => s.value == m.status,
        orElse: () => UserStatus.pending,
      ),
      roleId: m.roleId,
      imageUrl: m.imageUrl,
      fileName: m.fileName,
      initialName: m.initialName,
      planningConstraints: _decodePlanningConstraints(
        m.planningConstraintsJson,
      ),
    );
  }

  String? _encodePlanningConstraints(
    TeamMemberPlanningConstraintsEntity? constraints,
  ) {
    if (constraints == null) {
      return null;
    }
    return jsonEncode({
      'workerType': constraints.workerType,
      'availableWeekdays': constraints.availableWeekdays,
      'preferredShiftTypes': constraints.preferredShiftTypes,
      'blockedShiftTypes': constraints.blockedShiftTypes,
      'unavailableDateRanges': constraints.unavailableDateRanges,
      'minDailyHours': constraints.minDailyHours,
      'maxDailyHours': constraints.maxDailyHours,
      'maxWeeklyHours': constraints.maxWeeklyHours,
      'maxMonthlyHours': constraints.maxMonthlyHours,
      'overtimeAllowed': constraints.overtimeAllowed,
      'avoidConsecutiveShifts': constraints.avoidConsecutiveShifts,
      'requiresCoworkerPresence': constraints.requiresCoworkerPresence,
      'minRestHoursBetweenShifts': constraints.minRestHoursBetweenShifts,
      'maxConsecutiveNightShifts': constraints.maxConsecutiveNightShifts,
      'maxConsecutiveWeekendShifts': constraints.maxConsecutiveWeekendShifts,
      'assignedDailyMinutes': constraints.assignedDailyMinutes,
      'assignedWeeklyMinutes': constraints.assignedWeeklyMinutes,
      'assignedMonthlyMinutes': constraints.assignedMonthlyMinutes,
      'notes': constraints.notes,
    });
  }

  TeamMemberPlanningConstraintsEntity? _decodePlanningConstraints(
    String? rawJson,
  ) {
    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(rawJson) as Map<String, dynamic>;
      return TeamMemberPlanningConstraintsEntity(
        workerType: json['workerType']?.toString(),
        availableWeekdays:
            (json['availableWeekdays'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(),
        preferredShiftTypes:
            (json['preferredShiftTypes'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(),
        blockedShiftTypes:
            (json['blockedShiftTypes'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(),
        unavailableDateRanges:
            (json['unavailableDateRanges'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(),
        minDailyHours: (json['minDailyHours'] as num?)?.toInt(),
        maxDailyHours: (json['maxDailyHours'] as num?)?.toInt(),
        maxWeeklyHours: (json['maxWeeklyHours'] as num?)?.toInt(),
        maxMonthlyHours: (json['maxMonthlyHours'] as num?)?.toInt(),
        overtimeAllowed: json['overtimeAllowed'] as bool?,
        avoidConsecutiveShifts: json['avoidConsecutiveShifts'] as bool?,
        requiresCoworkerPresence: json['requiresCoworkerPresence'] as bool?,
        minRestHoursBetweenShifts: (json['minRestHoursBetweenShifts'] as num?)
            ?.toInt(),
        maxConsecutiveNightShifts: (json['maxConsecutiveNightShifts'] as num?)
            ?.toInt(),
        maxConsecutiveWeekendShifts:
            (json['maxConsecutiveWeekendShifts'] as num?)?.toInt(),
        assignedDailyMinutes: (json['assignedDailyMinutes'] as num?)?.toInt(),
        assignedWeeklyMinutes: (json['assignedWeeklyMinutes'] as num?)?.toInt(),
        assignedMonthlyMinutes: (json['assignedMonthlyMinutes'] as num?)
            ?.toInt(),
        notes: json['notes']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
