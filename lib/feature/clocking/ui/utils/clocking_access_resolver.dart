import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

class ClockingAccessResolver {
  static Future<bool> canManageClocking({
    required TeamEntity? team,
    required String currentUserId,
    required String currentUserEmail,
    required TeamMemberUseCase teamMemberUseCase,
    required RoleUseCase roleUseCase,
  }) async {
    if (team?.id == null) {
      return false;
    }
    if (team!.createdByUserId.trim() == currentUserId.trim()) {
      return true;
    }

    final members = await teamMemberUseCase.getAllMembersByTeamId(team.id!);
    final roles = await roleUseCase.getAllRolesByTeamId(team.id!);
    final member = members.cast<TeamMemberEntity?>().firstWhere(
      (item) =>
          item != null &&
          ((item.userId?.trim().isNotEmpty == true &&
                  item.userId!.trim() == currentUserId.trim()) ||
              item.userEmail.trim().toLowerCase() ==
                  currentUserEmail.trim().toLowerCase()),
      orElse: () => null,
    );
    if (member == null) {
      return false;
    }

    final permissions = _permissionsForRole(member.roleId, roles);
    final roleCode = member.roleId.trim().toUpperCase();
    return roleCode == 'OWNER' ||
        roleCode == 'ADMIN' ||
        permissions.contains('ADMIN') ||
        permissions.contains('MANAGE');
  }

  static Set<String> _permissionsForRole(String roleCode, List<RoleEntity> roles) {
    final role = roles.cast<RoleEntity?>().firstWhere(
      (item) => item?.id == roleCode,
      orElse: () => null,
    );
    final permissionsList = role?.permissions ?? const <String>[];
    if (permissionsList.isEmpty) {
      return switch (roleCode.trim().toUpperCase()) {
        'OWNER' => {'READ', 'UPDATE', 'ADMIN', 'DELETE', 'MANAGE'},
        'ADMIN' => {'READ', 'UPDATE', 'ADMIN', 'DELETE'},
        _ => {'READ'},
      };
    }
    return permissionsList
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}
