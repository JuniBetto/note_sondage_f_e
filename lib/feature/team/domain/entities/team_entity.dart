import 'package:flutter/material.dart';
import 'package:note_sondage/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:uuid/uuid.dart';

class TeamEntity {
  final String? id;
  final String name;
  final String description;
  final String createdByUserId;
  final DateTime createdAt;
  final String? color; // New field for team color

  TeamEntity(
    this.id,
    this.color, {
    required this.name,
    required this.description,
    required this.createdByUserId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
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
    DateTime? createdAt,
    required this.listMember,
  }) : super(
         id,
         color,
         name: name,
         description: description,
         createdByUserId: createdByUserId ?? '',
         createdAt: createdAt ?? DateTime.now(),
       );
  TeamUpdate copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    bool? isDeleted,
    String? createdAt,
    String? createdByUserId,
    List<TeamMemberUpdateTeam>? listMember,
  }) {
    return TeamUpdate(
      isDeleted ?? this.isDeleted,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt != null ? DateTime.parse(createdAt) : this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      listMember: listMember ?? this.listMember,
    );
  }
}
