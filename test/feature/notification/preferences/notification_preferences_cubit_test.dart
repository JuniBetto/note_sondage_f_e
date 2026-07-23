import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';

class _FakeBackendAuthDataSource extends BackendAuthDataSource {
  _FakeBackendAuthDataSource() : super(dio: Dio());

  Future<NotificationPreferencesEntity> Function()? getPreferencesHandler;
  Future<NotificationPreferencesEntity> Function(
    NotificationPreferencesEntity preferences,
  )?
  updatePreferencesHandler;

  int getPreferencesCalls = 0;
  final updateCalls = <NotificationPreferencesEntity>[];

  @override
  Future<NotificationPreferencesEntity> getNotificationPreferences() {
    getPreferencesCalls++;
    return getPreferencesHandler?.call() ??
        Future.value(NotificationPreferencesEntity.defaults);
  }

  @override
  Future<NotificationPreferencesEntity> updateNotificationPreferences(
    NotificationPreferencesEntity preferences,
  ) {
    updateCalls.add(preferences);
    return updatePreferencesHandler?.call(preferences) ??
        Future.value(preferences);
  }
}

class _SpyLocalNotificationService extends LocalNotificationService {
  final shiftNotificationsEnabledCalls = <bool>[];

  @override
  Future<void> setShiftNotificationsEnabled(bool enabled) async {
    shiftNotificationsEnabledCalls.add(enabled);
  }
}

void main() {
  late _FakeBackendAuthDataSource backendAuth;
  late _SpyLocalNotificationService localNotificationService;
  late NotificationPreferencesCubit cubit;

  setUp(() {
    backendAuth = _FakeBackendAuthDataSource();
    localNotificationService = _SpyLocalNotificationService();
    cubit = NotificationPreferencesCubit(
      backendAuth: backendAuth,
      localNotificationService: localNotificationService,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('NotificationPreferencesCubit', () {
    test(
      'loadPreferences loads backend preferences and syncs local shift setting',
      () async {
        final emittedStates = <NotificationPreferencesState>[];
        const preferences = NotificationPreferencesEntity(
          emailEnabled: true,
          pushEnabled: false,
          surveyRemindersEnabled: true,
          teamUpdatesEnabled: true,
          clockingAlertsEnabled: false,
          shiftAlertsEnabled: false,
          chatMessagesEnabled: true,
        );

        backendAuth.getPreferencesHandler = () async => preferences;
        final subscription = cubit.stream.listen(emittedStates.add);

        await cubit.loadPreferences();
        await pumpEventQueue(times: 10);

        expect(
          emittedStates.first.status,
          NotificationPreferencesStatus.loading,
        );
        expect(
          cubit.state,
          isA<NotificationPreferencesState>()
              .having(
                (state) => state.status,
                'status',
                NotificationPreferencesStatus.loaded,
              )
              .having(
                (state) => state.preferences?.shiftAlertsEnabled,
                'shift alerts',
                false,
              ),
        );
        expect(localNotificationService.shiftNotificationsEnabledCalls, [
          false,
        ]);

        await subscription.cancel();
      },
    );

    test(
      'loadPreferences skips duplicate fetch when state is already loaded',
      () async {
        backendAuth.getPreferencesHandler = () async =>
            NotificationPreferencesEntity.defaults;

        await cubit.loadPreferences();
        await pumpEventQueue(times: 10);
        await cubit.loadPreferences();
        await pumpEventQueue(times: 10);

        expect(backendAuth.getPreferencesCalls, 1);
      },
    );

    test(
      'updatePreferences emits saving then loaded and persists local shift setting',
      () async {
        final emittedStates = <NotificationPreferencesState>[];
        const initialPreferences = NotificationPreferencesEntity(
          emailEnabled: true,
          pushEnabled: true,
          surveyRemindersEnabled: true,
          teamUpdatesEnabled: true,
          clockingAlertsEnabled: true,
          shiftAlertsEnabled: true,
          chatMessagesEnabled: true,
        );
        const updatedPreferences = NotificationPreferencesEntity(
          emailEnabled: false,
          pushEnabled: true,
          surveyRemindersEnabled: false,
          teamUpdatesEnabled: true,
          clockingAlertsEnabled: true,
          shiftAlertsEnabled: false,
          chatMessagesEnabled: false,
        );

        backendAuth.getPreferencesHandler = () async => initialPreferences;
        backendAuth.updatePreferencesHandler = (_) async => updatedPreferences;
        await cubit.loadPreferences();
        await pumpEventQueue(times: 10);

        final subscription = cubit.stream.listen(emittedStates.add);

        await cubit.updatePreferences(updatedPreferences);
        await pumpEventQueue(times: 10);

        expect(
          emittedStates.first,
          isA<NotificationPreferencesState>()
              .having(
                (state) => state.status,
                'status',
                NotificationPreferencesStatus.saving,
              )
              .having(
                (state) => state.preferences?.shiftAlertsEnabled,
                'optimistic shift alerts',
                false,
              ),
        );
        expect(
          cubit.state,
          isA<NotificationPreferencesState>()
              .having(
                (state) => state.status,
                'status',
                NotificationPreferencesStatus.loaded,
              )
              .having(
                (state) => state.preferences?.chatMessagesEnabled,
                'saved chat messages',
                false,
              ),
        );
        expect(backendAuth.updateCalls, [updatedPreferences]);
        expect(
          localNotificationService.shiftNotificationsEnabledCalls.last,
          false,
        );

        await subscription.cancel();
      },
    );

    test(
      'updatePreferences restores previous preferences when backend update fails',
      () async {
        const initialPreferences = NotificationPreferencesEntity(
          emailEnabled: true,
          pushEnabled: true,
          surveyRemindersEnabled: true,
          teamUpdatesEnabled: true,
          clockingAlertsEnabled: true,
          shiftAlertsEnabled: true,
          chatMessagesEnabled: true,
        );
        const updatedPreferences = NotificationPreferencesEntity(
          emailEnabled: false,
          pushEnabled: false,
          surveyRemindersEnabled: false,
          teamUpdatesEnabled: false,
          clockingAlertsEnabled: false,
          shiftAlertsEnabled: false,
          chatMessagesEnabled: false,
        );

        backendAuth.getPreferencesHandler = () async => initialPreferences;
        backendAuth.updatePreferencesHandler = (_) =>
            Future<NotificationPreferencesEntity>.error(
              Exception('save failed'),
            );
        await cubit.loadPreferences();
        await pumpEventQueue(times: 10);

        await cubit.updatePreferences(updatedPreferences);
        await pumpEventQueue(times: 10);

        expect(cubit.state.status, NotificationPreferencesStatus.error);
        expect(cubit.state.preferences?.shiftAlertsEnabled, true);
        expect(cubit.state.preferences?.chatMessagesEnabled, true);
        expect(cubit.state.errorMessage, contains('save failed'));
      },
    );
  });
}
