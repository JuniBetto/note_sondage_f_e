import 'dart:convert';

import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_planning_constraints_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';

class TeamMemberMapper {
  static TeamMemberEntity fromJson(Map<String, dynamic> json) {
    return TeamMemberEntity(
      id: (json['id'] ?? json['memberId'])?.toString(),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      userEmail: (json['user_email'] ?? json['email'])?.toString() ?? '',
      teamId: (json['teamId'] ?? json['team_id'])?.toString() ?? '',
      status: UserStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () =>
            UserStatus.active, // Spring backend implies active if member
      ),
      roleId: (json['role_id'] ?? json['role'])?.toString() ?? '',
      imageUrl: (json['image_url'] ?? json['avatarUrl'])?.toString(),
      fileName: json['file_name']?.toString() ?? '',
      imageFile: json['image_file'],
      imageBytes: json['image_bytes'],
      initialName: (json['initialname'] ?? json['fullName'])?.toString() ?? '',
      planningConstraints: _planningConstraintsFromJson(
        json['planningConstraints'] as Map<String, dynamic>?,
      ),
    );
  }

  static Map<String, dynamic> toJson(TeamMemberEntity member) {
    return {
      if (member.id != null) 'id': member.id,
      if (member.userId != null) 'user_id': member.userId,
      'user_email': member.userEmail,
      'team_id': member.teamId,
      'status': member.status.value,
      'role_id': member.roleId,
      if (member.imageUrl != null) 'image_url': member.imageUrl,
      if (member.imageFile != null) 'image_file': member.imageFile,
      if (member.imageBytes != null)
        'image_bytes': base64Encode(member.imageBytes!),
      'file_name': member.fileName ?? '',
      'initialName': '',
    };
  }

  static Map<String, dynamic> toJsonForUpdate(TeamMemberUpdateTeam entity) {
    return {
      'userId': entity.userId,
      'email': entity.email,
      'status': entity.status,
      'teamMemberId': entity.teamMemberId,
      'imageUrl': entity.imageUrl,
      'role': entity.role,
    };
  }

  static TeamMemberUpdateTeam fromJsonUpdate(Map<String, dynamic> json) {
    return TeamMemberUpdateTeam(
      userId: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      teamMemberId: json['teamMember_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> planningConstraintsToJson(
    TeamMemberPlanningConstraintsEntity constraints,
  ) {
    return {
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
      'notes': constraints.notes,
    };
  }

  static TeamMemberPlanningConstraintsEntity? _planningConstraintsFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null || json.isEmpty) {
      return null;
    }
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
      maxConsecutiveWeekendShifts: (json['maxConsecutiveWeekendShifts'] as num?)
          ?.toInt(),
      assignedDailyMinutes: (json['assignedDailyMinutes'] as num?)?.toInt(),
      assignedWeeklyMinutes: (json['assignedWeeklyMinutes'] as num?)?.toInt(),
      assignedMonthlyMinutes: (json['assignedMonthlyMinutes'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
    );
  }
}
