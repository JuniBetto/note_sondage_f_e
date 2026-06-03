enum UserRole {
  owner('OWNER'),
  admin('ADMIN'),
  manager('MANAGER'),
  worker('WORKER');

  final String value;
  const UserRole(this.value);

  factory UserRole.fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.worker,
    );
  }

  /// True if the role can manage public shifts (create / edit public resources).
  bool get canManagePublicShifts =>
      this == UserRole.owner || this == UserRole.admin;

  @override
  String toString() => value;
}
