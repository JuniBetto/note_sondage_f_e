import 'package:note_sondage/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/invite_team_member_request_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';

class TeamEntity {
  final String? id;
  final String name;
  final String description;
  final String createdByUserId;
  final DateTime createdAt;
  final String? color; // New field for team color
  final bool clockingRequired;
  final String? clockingRequiredStartDate;
  final String? clockingReminderTime;
  final String? clockingMissingAlertTime;
  final String? clockingOpenAlertTime;
  final int memberCount;
  final List<PlanningWorkerTypeEntity> planningWorkerTypes;
  final List<InviteTeamMemberRequestEntity>?
  pendingInvitations; // New field for pending invitations

  TeamEntity(
    this.id,
    this.color,
    this.pendingInvitations, {
    required this.name,
    required this.description,
    required this.createdByUserId,
    this.clockingRequired = false,
    this.clockingRequiredStartDate,
    this.clockingReminderTime,
    this.clockingMissingAlertTime,
    this.clockingOpenAlertTime,
    this.memberCount = 0,
    this.planningWorkerTypes = PlanningWorkerTypeEntity.builtIns,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  copyWith({
    required String name,
    required String description,
    String? color,
    required String createdByUserId,
  }) {}
}

class TeamMemberforView {
  final TeamMemberEntity teamMember;
  final UserEntity?
  user; // Aggiungi un campo opzionale per l'entità User associata

  TeamMemberforView({required this.teamMember, this.user});

  copyWith({TeamMemberEntity? teamMember, UserEntity? user}) {
    return TeamMemberforView(
      teamMember: teamMember ?? this.teamMember,
      user: user ?? this.user,
    );
  }
}

class TeamEntityForView {
  final TeamEntity team;
  List<TeamMemberforView> members;

  TeamEntityForView({required this.team, required this.members});

  copyWith({TeamEntity? team, List<TeamMemberforView>? members}) {
    return TeamEntityForView(
      team: team ?? this.team,
      members: members ?? this.members,
    );
  }
}

class TeamUpdate extends TeamEntity {
  final bool? isDeleted; // New field to indicate if the team is deleted
  final List<TeamMemberUpdateTeam> listMember;

  TeamUpdate(
    this.isDeleted, {
    required String? id,
    required String name,
    required String description,
    required String? createdByUserId,
    String? color,
    bool clockingRequired = false,
    String? clockingRequiredStartDate,
    String? clockingReminderTime,
    String? clockingMissingAlertTime,
    String? clockingOpenAlertTime,
    DateTime? createdAt,
    List<PlanningWorkerTypeEntity> planningWorkerTypes =
        PlanningWorkerTypeEntity.builtIns,
    required this.listMember,
  }) : super(
         id,
         color,
         null, // pendingInvitations not used in update
         name: name,
         description: description,
         createdByUserId: createdByUserId ?? '',
         clockingRequired: clockingRequired,
         clockingRequiredStartDate: clockingRequiredStartDate,
         clockingReminderTime: clockingReminderTime,
         clockingMissingAlertTime: clockingMissingAlertTime,
         clockingOpenAlertTime: clockingOpenAlertTime,
         memberCount: 0,
         planningWorkerTypes: planningWorkerTypes,
         createdAt: createdAt ?? DateTime.now(),
       );
  @override
  TeamUpdate copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    bool? isDeleted,
    String? createdAt,
    String? createdByUserId,
    bool? clockingRequired,
    String? clockingRequiredStartDate,
    String? clockingReminderTime,
    String? clockingMissingAlertTime,
    String? clockingOpenAlertTime,
    List<PlanningWorkerTypeEntity>? planningWorkerTypes,
    List<TeamMemberUpdateTeam>? listMember,
  }) {
    return TeamUpdate(
      isDeleted ?? this.isDeleted,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      clockingRequired: clockingRequired ?? this.clockingRequired,
      clockingRequiredStartDate:
          clockingRequiredStartDate ?? this.clockingRequiredStartDate,
      clockingReminderTime: clockingReminderTime ?? this.clockingReminderTime,
      clockingMissingAlertTime:
          clockingMissingAlertTime ?? this.clockingMissingAlertTime,
      clockingOpenAlertTime:
          clockingOpenAlertTime ?? this.clockingOpenAlertTime,
      planningWorkerTypes: planningWorkerTypes ?? this.planningWorkerTypes,
      createdAt: createdAt != null ? DateTime.parse(createdAt) : this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      listMember: listMember ?? this.listMember,
    );
  }
}
