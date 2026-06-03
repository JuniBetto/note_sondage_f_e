class UserClockInfo {
  final String user;
  final String clockInTime;
  final String clockOutTime;
  final String timeWorked;
  final String teamName;

  UserClockInfo({
    required this.user,
    required this.clockInTime,
    required this.clockOutTime,
    required this.timeWorked,
    required this.teamName,
  });

  UserClockInfo copyWith({
    String? user,
    String? clockInTime,
    String? clockOutTime,
    String? timeWorked,
    String? teamName,
  }) {
    return UserClockInfo(
      user: user ?? this.user,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      timeWorked: timeWorked ?? this.timeWorked,
      teamName: teamName ?? this.teamName,
    );
  }
}
