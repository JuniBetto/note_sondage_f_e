enum LoginType { microsoft, google, facebook }

enum ApiType { express, python }

enum UserRole {
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

  @override
  String toString() => value;
}

enum SettingCategory {
  theme,
  language,
  notifications,
  privacy,
  contactus,
  appearance,
  account,
  security,
  general,
}
