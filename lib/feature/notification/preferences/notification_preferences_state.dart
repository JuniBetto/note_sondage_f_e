part of 'notification_preferences_cubit.dart';

enum NotificationPreferencesStatus { initial, loading, loaded, saving, error }

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.initial,
    this.preferences,
    this.errorMessage,
  });

  final NotificationPreferencesStatus status;
  final NotificationPreferencesEntity? preferences;
  final String? errorMessage;

  NotificationPreferencesEntity get effectivePreferences =>
      preferences ?? NotificationPreferencesEntity.defaults;

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferencesEntity? preferences,
    String? errorMessage,
  }) {
    return NotificationPreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, preferences, errorMessage];
}
