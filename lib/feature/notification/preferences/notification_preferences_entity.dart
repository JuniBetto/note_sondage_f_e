class NotificationPreferencesEntity {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool surveyRemindersEnabled;
  final bool teamUpdatesEnabled;
  final bool clockingAlertsEnabled;

  const NotificationPreferencesEntity({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.surveyRemindersEnabled,
    required this.teamUpdatesEnabled,
    required this.clockingAlertsEnabled,
  });

  static const defaults = NotificationPreferencesEntity(
    emailEnabled: true,
    pushEnabled: true,
    surveyRemindersEnabled: true,
    teamUpdatesEnabled: true,
    clockingAlertsEnabled: true,
  );

  factory NotificationPreferencesEntity.fromJson(Map<String, dynamic> json) {
    bool readBool(String key, bool fallback) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return fallback;
    }

    return NotificationPreferencesEntity(
      emailEnabled: readBool('emailEnabled', true),
      pushEnabled: readBool('pushEnabled', true),
      surveyRemindersEnabled: readBool('surveyRemindersEnabled', true),
      teamUpdatesEnabled: readBool('teamUpdatesEnabled', true),
      clockingAlertsEnabled: readBool('clockingAlertsEnabled', true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailEnabled': emailEnabled,
      'pushEnabled': pushEnabled,
      'surveyRemindersEnabled': surveyRemindersEnabled,
      'teamUpdatesEnabled': teamUpdatesEnabled,
      'clockingAlertsEnabled': clockingAlertsEnabled,
    };
  }

  NotificationPreferencesEntity copyWith({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? surveyRemindersEnabled,
    bool? teamUpdatesEnabled,
    bool? clockingAlertsEnabled,
  }) {
    return NotificationPreferencesEntity(
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      surveyRemindersEnabled:
          surveyRemindersEnabled ?? this.surveyRemindersEnabled,
      teamUpdatesEnabled: teamUpdatesEnabled ?? this.teamUpdatesEnabled,
      clockingAlertsEnabled: clockingAlertsEnabled ?? this.clockingAlertsEnabled,
    );
  }
}
