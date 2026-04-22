class InviteTeamMemberRequestEntity {
  final String email;
  final String roleId;

  InviteTeamMemberRequestEntity({required this.email, required this.roleId});

  InviteTeamMemberRequestEntity copyWith({String? email, String? roleId}) {
    return InviteTeamMemberRequestEntity(
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
    );
  }
}
