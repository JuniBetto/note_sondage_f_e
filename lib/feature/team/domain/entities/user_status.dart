//enum UserStatus { active, deleted, disabled, banned }
enum UserStatus {
  pending('INVITED'),
  active('ACTIVATE'),
  deactivated('DEACTIVATED'),
  deleted('SUSPENDED'),
  banned('PENDING');

  final String value;
  const UserStatus(this.value);

  factory UserStatus.fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.pending,
    );
  }

  @override
  String toString() => value;
}
