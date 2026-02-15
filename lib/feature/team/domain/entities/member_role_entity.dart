import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';

class MemberRoleEntity {
  final TeamMemberEntity member;
  final RoleEntity role;

  MemberRoleEntity({required this.member, required this.role});
}
