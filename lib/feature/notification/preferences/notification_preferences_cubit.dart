import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';

part 'notification_preferences_state.dart';

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({required BackendAuthDataSource backendAuth})
    : _backendAuth = backendAuth,
      super(const NotificationPreferencesState());

  final BackendAuthDataSource _backendAuth;

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
      final preferences = await _backendAuth.getNotificationPreferences();
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.loaded,
          preferences: preferences,
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
      final saved = await _backendAuth.updateNotificationPreferences(preferences);
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.loaded,
          preferences: saved,
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
