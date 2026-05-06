import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/app_lifecycle_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/home/ui/bloc/dashboard_bloc.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/local/notification_action_intent.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/notification/push/push_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/clocking_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/sondage_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/navigation/notification_navigation.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/notification/realtime/team_realtime_coordinator.dart';
import 'package:note_sondage/feature/shift/notification/shift_alarm_scheduler.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/languages/l10n/l10n.dart';
import 'package:note_sondage/ui/app_keys.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/setting_Navigation_bloc/setting_navigation_bloc.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_bloc.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_state.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';

import '../feature/auth/domain/entities/auth_user_entity.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  GoRouter? _router;
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;
  StreamSubscription<RealtimeNotification>? _pushSubscription;
  StreamSubscription<NotificationActionIntent>? _localActionSubscription;
  final List<String> _processedNotificationIds = <String>[];

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = getIt<RealtimeNotificationService>().stream.listen(
      _handleRealtimeNotification,
    );
    _pushSubscription = getIt<PushNotificationService>().stream.listen(
      _handleRealtimeNotification,
    );
    _localActionSubscription = getIt<LocalNotificationService>().actions.listen(
      (action) async {
        await _handleLocalNotificationAction(action);
      },
    );
    unawaited(_drainPendingLocalNotificationActions());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncServicesForAuthState(getIt<AuthBloc>().state, resetCaches: true);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _pushSubscription?.cancel();
    _localActionSubscription?.cancel();
    super.dispose();
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
    if (_isDuplicateNotification(notification.notificationId)) {
      return;
    }

    final currentUserId = getIt<AuthBloc>().state.user.uid;
    final teamDecision = getIt<TeamRealtimeCoordinator>().resolveGlobalDecision(
      notification,
      currentUserId: currentUserId,
    );
    final selectedClockingTeamId = _selectedClockingTeamId(
      getIt<ClockingBloc>().state,
    );
    final clockingDecision = getIt<ClockingRealtimeCoordinator>()
        .resolveDecision(
          notification,
          currentUserId: currentUserId,
          selectedTeamId: selectedClockingTeamId,
        );
    final sondageDecision = getIt<SondageRealtimeCoordinator>().resolveDecision(
      notification,
    );
    final shiftDecision = getIt<ShiftRealtimeCoordinator>().resolveDecision(
      notification,
      currentUserId: currentUserId,
    );
    getIt<NotificationCenterCubit>().ingestRealtimeNotification(notification);

    if (!teamDecision.hasWork &&
        !clockingDecision.refreshClocking &&
        !clockingDecision.refreshDashboard &&
        !sondageDecision.refreshSondages &&
        !sondageDecision.refreshDashboard &&
        !shiftDecision.refreshCalendar) {
      return;
    }

    if (teamDecision.refreshTeams) {
      getIt<TeamBloc>().add(LoadTeamsEvent());
    }
    if (teamDecision.refreshDashboard) {
      getIt<DashboardBloc>().add(RefreshDashboardEvent());
    }
    if (clockingDecision.refreshClocking) {
      getIt<ClockingBloc>().add(
        LoadClockingRecordsEvent(teamId: selectedClockingTeamId),
      );
    }
    if (clockingDecision.refreshDashboard) {
      getIt<DashboardBloc>().add(RefreshDashboardEvent());
    }
    if (sondageDecision.refreshSondages) {
      getIt<SondageBloc>().add(LoadSondagesEvent());
    }
    if (sondageDecision.refreshDashboard) {
      getIt<DashboardBloc>().add(RefreshDashboardEvent());
    }
    if (shiftDecision.refreshCalendar) {
      getIt<DashboardBloc>().add(RefreshDashboardEvent());
      // Se il ShiftBloc ha già caricato un range, ricaricalo con lo stesso
      // range così il calendario viene aggiornato anche se l'utente non è
      // sulla pagina shift in quel momento.
      final shiftState = getIt<ShiftBloc>().state;
      if (shiftState is ShiftAssignmentsLoaded) {
        final now = DateTime.now();
        final first = DateTime(now.year, now.month, 1);
        final last = DateTime(now.year, now.month + 1, 0);
        getIt<ShiftBloc>().add(
          LoadShiftAssignmentsEvent(from: first, to: last),
        );
      }
    }
    if (shiftDecision.showAlarmBanner) {
      final alarmShiftId =
          notification.metadata['shiftId'] ??
          notification.metadata['assignmentId'] ??
          notification.notificationId;
      if (kIsWeb) {
        _showShiftAlarmSnackBar(
          assignmentId: alarmShiftId,
          shiftDate: notification.metadata['shiftDate'],
          profileName: shiftDecision.alarmProfileName ?? '',
          shiftDateLabel: shiftDecision.alarmShiftDate ?? '',
          minutesBefore: shiftDecision.alarmMinutesBefore ?? 0,
        );
      } else {
        unawaited(
          getIt<LocalNotificationService>().showShiftAlarmNotification(
            shiftId: alarmShiftId,
            profileName: shiftDecision.alarmProfileName ?? '',
            shiftDate: shiftDecision.alarmShiftDate ?? '',
            minutesBefore: shiftDecision.alarmMinutesBefore ?? 0,
          ),
        );
      }
    }
    if (teamDecision.showSnackBar && teamDecision.snackBarMessage != null) {
      final messenger = scaffoldMessengerKey.currentState;
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(content: Text(teamDecision.snackBarMessage!)),
      );
    }
  }

  /// Mostra uno SnackBar di allarme turno sull'interfaccia web.
  /// Rimane visibile 12 secondi e offre il bottone "Apri turno" che
  /// naviga alla pagina shift e pre-seleziona il turno corretto.
  void _showShiftAlarmSnackBar({
    required String assignmentId,
    required String? shiftDate,
    required String profileName,
    required String shiftDateLabel,
    required int minutesBefore,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final title = '⏰ Turno tra $minutesBefore min';
    final body = profileName.isNotEmpty
        ? 'Shift "$profileName"${shiftDateLabel.isNotEmpty ? ' — $shiftDateLabel' : ''}'
        : 'Il tuo turno inizia presto';

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        action: SnackBarAction(
          label: 'Apri turno',
          onPressed: () {
            getIt<ShiftOpenIntentController>().queue(
              assignmentId: assignmentId,
              shiftDate: shiftDate,
            );
            unawaited(NotificationNavigation.openShifts());
          },
        ),
      ),
    );
  }

  Future<void> _handleLocalNotificationAction(
    NotificationActionIntent action,
  ) async {
    // ── Shift alarm tap → naviga al turno ────────────────────────────────────
    if (action.metadata['eventType'] == 'SHIFT_ALARM') {
      final assignmentId = action.metadata['assignmentId'];
      final shiftDateRaw = action.metadata['shiftDate'];
      getIt<ShiftOpenIntentController>().queue(
        assignmentId: assignmentId,
        shiftDate: shiftDateRaw,
      );
      if (mounted) {
        await NotificationNavigation.openShifts(context: context);
      }
      return;
    }

    // ── Team invite / altri ───────────────────────────────────────────────────
    await getIt<NotificationCenterCubit>().handleActionIntent(
      notificationId: action.notificationId,
      actionId: action.actionId,
      metadata: action.metadata,
    );
    if (!mounted) return;
    getIt<TeamBloc>().add(LoadTeamsEvent());
    getIt<DashboardBloc>().add(RefreshDashboardEvent());
  }

  Future<void> _drainPendingLocalNotificationActions() async {
    final pendingActions = await getIt<LocalNotificationService>()
        .drainPendingActionIntents();
    for (final action in pendingActions) {
      await _handleLocalNotificationAction(action);
    }
  }

  void _syncServicesForAuthState(AuthState state, {bool resetCaches = false}) {
    final realtimeService = getIt<RealtimeNotificationService>();
    final pushNotificationService = getIt<PushNotificationService>();
    final teamBloc = getIt<TeamBloc>();
    final sondageBloc = getIt<SondageBloc>();
    final notificationPreferencesCubit = getIt<NotificationPreferencesCubit>();
    final notificationCenterCubit = getIt<NotificationCenterCubit>();

    if (state.status == AuthStatus.authenticated && state.user.uid.isNotEmpty) {
      realtimeService.connect(state.user.uid);
      unawaited(pushNotificationService.syncDeviceRegistration());
      unawaited(notificationPreferencesCubit.loadPreferences());
      unawaited(notificationCenterCubit.loadNotifications(force: true));
      // Avvia lo scheduler allarmi turni
      getIt<ShiftAlarmScheduler>().start();
      if (resetCaches) {
        _processedNotificationIds.clear();
        teamBloc.add(const ResetTeamCacheEvent());
        sondageBloc.add(const ResetSondageCacheEvent());
      }
      return;
    }

    if (state.status == AuthStatus.unauthenticated) {
      realtimeService.disconnect();
      notificationPreferencesCubit.reset();
      notificationCenterCubit.reset();
      _processedNotificationIds.clear();
      teamBloc.add(const ResetTeamCacheEvent());
      sondageBloc.add(const ResetSondageCacheEvent());
      // Ferma lo scheduler allarmi turni
      getIt<ShiftAlarmScheduler>().stop();
    }
  }

  String? _selectedClockingTeamId(ClockingState state) {
    if (state is ClockingRecordsLoaded) return state.selectedTeamId;
    if (state is ClockingActionInProgress) return state.selectedTeamId;
    if (state is ClockingActionSuccess) return state.selectedTeamId;
    return null;
  }

  bool _isDuplicateNotification(String notificationId) {
    if (notificationId.isEmpty) {
      return false;
    }
    if (_processedNotificationIds.contains(notificationId)) {
      return true;
    }
    _processedNotificationIds.add(notificationId);
    if (_processedNotificationIds.length > 100) {
      _processedNotificationIds.removeAt(0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        BlocProvider<LanguageBloc>(create: (context) => LanguageBloc()),
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<AppLifecycleBloc>.value(value: getIt<AppLifecycleBloc>()),
        BlocProvider<NotificationPreferencesCubit>.value(
          value: getIt<NotificationPreferencesCubit>(),
        ),
        BlocProvider<NotificationCenterCubit>.value(
          value: getIt<NotificationCenterCubit>(),
        ),
        BlocProvider<NavigationBloc>(create: (context) => NavigationBloc()),
        BlocProvider<SettingNavigationBloc>(
          create: (context) => SettingNavigationBloc(),
        ),
        BlocProvider<TeamBloc>.value(value: getIt<TeamBloc>()),
        BlocProvider<RoleBloc>(create: (context) => getIt<RoleBloc>()),
        BlocProvider<SondageBloc>(create: (context) => getIt<SondageBloc>()),
        BlocProvider<ClockingBloc>(create: (context) => getIt<ClockingBloc>()),
        BlocProvider<DashboardBloc>(
          create: (context) => getIt<DashboardBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, languageState) {
              _router ??= createRouter(context);

              return BlocListener<AuthBloc, AuthState>(
                listenWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.user.uid != current.user.uid,
                listener: (context, state) {
                  _syncServicesForAuthState(state, resetCaches: true);
                },
                child: MaterialApp.router(
                  title: 'Flutter Demo',
                  debugShowCheckedModeBanner: false,
                  routerConfig: _router,
                  scaffoldMessengerKey: scaffoldMessengerKey,
                  theme: themeState.themeData,
                  themeMode: ThemeMode.system,
                  supportedLocales: L10n.all,
                  locale: languageState.locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
