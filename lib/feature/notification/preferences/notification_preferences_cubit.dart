import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';

part 'notification_preferences_state.dart';

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    required BackendAuthDataSource backendAuth,
    required LocalNotificationService localNotificationService,
  }) : _backendAuth = backendAuth,
      _localNotificationService = localNotificationService,
      super(const NotificationPreferencesState());

  final BackendAuthDataSource _backendAuth;
  final LocalNotificationService _localNotificationService;

  Future<void> loadPreferences({bool force = false}) async {
    if (state.status == NotificationPreferencesStatus.loading) {
      return;
    }
    if (!force &&
        state.status == NotificationPreferencesStatus.loaded &&
        state.preferences != null) {
      return;
    }

    emit(state.copyWith(status: NotificationPreferencesStatus.loading));
    try {
      final backendPreferences = await _backendAuth.getNotificationPreferences();
      await _localNotificationService.setShiftNotificationsEnabled(
        backendPreferences.shiftAlertsEnabled,
      );
      // Keeps the locally-scheduled task reminder alarms in sync with the
      // backend value (which is now the source of truth for this toggle).
      await _localNotificationService.setTaskNotificationsEnabled(
        backendPreferences.taskRemindersEnabled,
      );
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.loaded,
          preferences: backendPreferences,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> updatePreferences(NotificationPreferencesEntity preferences) async {
    final previous = state.preferences;
    emit(
      state.copyWith(
        status: NotificationPreferencesStatus.saving,
        preferences: preferences,
        errorMessage: null,
      ),
    );
    try {
      final backendSaved = await _backendAuth.updateNotificationPreferences(
        preferences,
      );
      await _localNotificationService.setShiftNotificationsEnabled(
        backendSaved.shiftAlertsEnabled,
      );
      await _localNotificationService.setTaskNotificationsEnabled(
        backendSaved.taskRemindersEnabled,
      );
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.loaded,
          preferences: backendSaved,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.error,
          preferences: previous,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void reset() {
    emit(const NotificationPreferencesState());
  }
}
