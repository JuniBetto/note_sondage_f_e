/// Per-member override of the team's clocking alarm times (HH:mm). Any field
/// left null falls back to the team-wide default for that specific alarm.
class TeamMemberClockingAlarmOverrideEntity {
  const TeamMemberClockingAlarmOverrideEntity({
    this.reminderTime,
    this.missingAlertTime,
    this.openAlertTime,
  });

  final String? reminderTime;
  final String? missingAlertTime;
  final String? openAlertTime;

  bool get isEmpty =>
      reminderTime == null && missingAlertTime == null && openAlertTime == null;

  TeamMemberClockingAlarmOverrideEntity copyWith({
    String? reminderTime,
    String? missingAlertTime,
    String? openAlertTime,
  }) {
    return TeamMemberClockingAlarmOverrideEntity(
      reminderTime: reminderTime ?? this.reminderTime,
      missingAlertTime: missingAlertTime ?? this.missingAlertTime,
      openAlertTime: openAlertTime ?? this.openAlertTime,
    );
  }
}
