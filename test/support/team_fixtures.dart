import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';

TeamEntity buildTeam({
  String id = 'team-1',
  String name = 'Product',
  String description = 'Product team',
  String createdByUserId = 'owner-1',
  String color = '#4A90E2',
  int memberCount = 2,
  DateTime? createdAt,
}) {
  return TeamEntity(
    id,
    color,
    null,
    name: name,
    description: description,
    createdByUserId: createdByUserId,
    memberCount: memberCount,
    createdAt: createdAt ?? DateTime.utc(2024, 1, 1),
  );
}

TeamUpdate buildTeamUpdate({
  String id = 'team-1',
  String name = 'Product Updated',
  String description = 'Updated description',
  String createdByUserId = 'owner-1',
  String color = '#4A90E2',
  bool isDeleted = false,
  List<TeamMemberUpdateTeam> listMember = const [],
}) {
  return TeamUpdate(
    isDeleted,
    id: id,
    name: name,
    description: description,
    createdByUserId: createdByUserId,
    color: color,
    createdAt: DateTime.utc(2024, 1, 2),
    listMember: listMember,
  );
}

List<Map<String, dynamic>> buildTeamMembersViewData() {
  return const [
    {
      'name': 'Alice Doe',
      'email': 'alice@example.com',
      'role': 'admin',
      'status': 'active',
      'imageUrl': '',
      'color': Colors.teal,
    },
    {
      'name': 'Bob Smith',
      'email': 'bob@example.com',
      'role': 'member',
      'status': 'active',
      'imageUrl': '',
      'color': Colors.orange,
    },
    {
      'name': 'Charlie Stone',
      'email': 'charlie@example.com',
      'role': 'member',
      'status': 'active',
      'imageUrl': '',
      'color': Colors.indigo,
    },
  ];
}
