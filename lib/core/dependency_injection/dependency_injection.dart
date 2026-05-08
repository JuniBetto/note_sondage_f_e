import 'package:note_sondage/feature/notification/realtime/shift_realtime_coordinator.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/infrastructure/data_source/shift_remote_data_source.dart';
import 'package:note_sondage/feature/shift/infrastructure/repositories/shift_repository_impl.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/shift/notification/shift_alarm_scheduler.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/auth/domain/repositories/auth_repository.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/infrastructure/repositories/firebase_auth_repository_impl.dart';
import 'package:note_sondage/feature/auth/ui/bloc/app_lifecycle_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/repositories/clocking_repository.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_local/clocking_local_data_source.dart';
import 'package:note_sondage/feature/clocking/infrastructure/data_source/data_source_remote/clocking_remote_data_source.dart';
import 'package:note_sondage/feature/clocking/infrastructure/repositories/clocking_repository_impl.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/home/domain/repositories/dashboard_repository.dart';
import 'package:note_sondage/feature/home/domain/use_case/dashboard_use_case.dart';
import 'package:note_sondage/feature/home/infrastructure/repositories/dashboard_repository_impl.dart';
import 'package:note_sondage/feature/home/ui/bloc/dashboard_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/notification/push/push_notification_service.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_cubit.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/realtime/team_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/sondage_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/clocking_realtime_coordinator.dart';
import 'package:note_sondage/feature/sondage/domain/repositories/sondage_repository.dart';
import 'package:note_sondage/feature/sondage/domain/use_case/sondage_use_case.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_local/sondage_local_data_source.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_remote/sondage_remote_data_source.dart';
import 'package:note_sondage/feature/sondage/infrastructure/repositories/sondage_repository_impl.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/team/domain/repositories/permission_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/role_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_member_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/team_repository.dart';
import 'package:note_sondage/feature/team/domain/repositories/user_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/permission/permission_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/user/user_use_case.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/permission_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/role_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/team_member_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/user_local_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/permission_remote_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/role_remote_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_member_remote_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/team_remote_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_remote/user_remote_data_source.dart';
import 'package:note_sondage/feature/team/infrastructure/repositories/permission_repository_impl.dart';
import 'package:note_sondage/feature/team/infrastructure/repositories/role_repository_impl.dart';
import 'package:note_sondage/feature/team/infrastructure/repositories/team_member_repository_impl.dart';
import 'package:note_sondage/feature/team/infrastructure/repositories/team_repository_impl.dart';
import 'package:note_sondage/feature/team/infrastructure/repositories/user_repository_impl.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/user/user_bloc.dart';

final getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setup() async {
  _registerAuth();
  _registerDataSources();
  _registerRepositories();
  _registerUseCases();
  _registerBlocs();
  _registerShift();
}

// ==================== AUTH (Firebase) ====================

void _registerAuth() {
  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepositoryImpl(),
  );

  // Use Case
  getIt.registerLazySingleton<AuthUseCase>(
    () => AuthUseCase(getIt<AuthRepository>()),
  );

  // Auth BLoC — singleton, ascolta lo stream di Firebase Auth
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authUseCase: getIt<AuthUseCase>()),
  );

  // App Lifecycle BLoC — gestisce background/foreground
  getIt.registerLazySingleton<AppLifecycleBloc>(
    () => AppLifecycleBloc(authBloc: getIt<AuthBloc>()),
  );
}

// ==================== DATA SOURCES ====================

void _registerDataSources() {
  getIt.registerLazySingleton<UserArchiveService>(() => UserArchiveService());

  // Local data sources
  getIt.registerLazySingleton<PermissionLocalDataSource>(
    () => PermissionLocalDataSource(),
  );
  getIt.registerLazySingleton<RoleLocalDataSource>(() => RoleLocalDataSource());
  getIt.registerLazySingleton<TeamLocalDataSource>(() => TeamLocalDataSource());
  getIt.registerLazySingleton<TeamMemberLocalDataSource>(
    () => TeamMemberLocalDataSource(),
  );
  getIt.registerLazySingleton<UserLocalDataSource>(() => UserLocalDataSource());

  // Sondage local data source
  getIt.registerLazySingleton<SondageLocalDataSource>(
    () => SondageLocalDataSource(),
  );

  // Clocking local data source
  getIt.registerLazySingleton<ClockingLocalDataSource>(
    () => ClockingLocalDataSource(),
  );

  // Realtime notifications
  getIt.registerLazySingleton<RealtimeNotificationService>(
    () => RealtimeNotificationService(),
  );

  // Remote data sources (inject local data source for caching)
  getIt.registerLazySingleton<PermissionRemoteDataSource>(
    () => PermissionRemoteDataSource(getIt<PermissionLocalDataSource>()),
  );
  getIt.registerLazySingleton<RoleRemoteDataSource>(
    () => RoleRemoteDataSource(getIt<RoleLocalDataSource>()),
  );
  getIt.registerLazySingleton<TeamRemoteDataSource>(
    () => TeamRemoteDataSource(getIt<TeamLocalDataSource>()),
  );
  getIt.registerLazySingleton<TeamMemberRemoteDataSource>(
    () => TeamMemberRemoteDataSource(getIt<TeamMemberLocalDataSource>()),
  );
  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSource(getIt<UserLocalDataSource>()),
  );

  // Sondage remote data source
  getIt.registerLazySingleton<SondageRemoteDataSource>(
    () => SondageRemoteDataSource(getIt<SondageLocalDataSource>()),
  );

  // Clocking remote data source
  getIt.registerLazySingleton<ClockingRemoteDataSource>(
    () => ClockingRemoteDataSource(getIt<ClockingLocalDataSource>()),
  );
}

// ==================== REPOSITORIES ====================

void _registerRepositories() {
  // Permission
  getIt.registerLazySingleton<PermissionRepository>(
    () => PermissionRepositoryImpl(
      getIt<PermissionLocalDataSource>(),
      getIt<PermissionRemoteDataSource>(),
    ),
  );

  // Role
  getIt.registerLazySingleton<RoleRepository>(
    () => RoleRepositoryImpl(
      getIt<RoleLocalDataSource>(),
      getIt<RoleRemoteDataSource>(),
    ),
  );

  // Team
  getIt.registerLazySingleton<TeamRepository>(
    () => TeamRepositoryImpl(
      getIt<TeamLocalDataSource>(),
      getIt<TeamRemoteDataSource>(),
    ),
  );

  // TeamMember
  getIt.registerLazySingleton<TeamMemberRepository>(
    () => TeamMemberRepositoryImpl(
      getIt<TeamMemberLocalDataSource>(),
      getIt<TeamMemberRemoteDataSource>(),
    ),
  );

  // User
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      local: getIt<UserLocalDataSource>(),
      remote: getIt<UserRemoteDataSource>(),
    ),
  );

  // Sondage
  getIt.registerLazySingleton<SondageRepository>(
    () => SondageRepositoryImpl(
      getIt<SondageLocalDataSource>(),
      getIt<SondageRemoteDataSource>(),
    ),
  );

  // Clocking
  getIt.registerLazySingleton<ClockingRepository>(
    () => ClockingRepositoryImpl(
      getIt<ClockingLocalDataSource>(),
      getIt<ClockingRemoteDataSource>(),
    ),
  );

  // Dashboard
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      teamRemote: getIt<TeamRemoteDataSource>(),
      teamMemberRemote: getIt<TeamMemberRemoteDataSource>(),
      sondageRemote: getIt<SondageRemoteDataSource>(),
      clockingRemote: getIt<ClockingRemoteDataSource>(),
      shiftRemote: getIt<ShiftRemoteDataSource>(),
    ),
  );
}

// ==================== USE CASES ====================

void _registerUseCases() {
  // Permission
  getIt.registerLazySingleton<PermissionUseCase>(
    () => PermissionUseCase(getIt<PermissionRepository>()),
  );

  // Role
  getIt.registerLazySingleton<RoleUseCase>(
    () => RoleUseCase(getIt<RoleRepository>()),
  );

  // Team
  getIt.registerLazySingleton<TeamUseCase>(
    () => TeamUseCase(getIt<TeamRepository>()),
  );

  // User - Registrato prima di TeamMember perché TeamMemberUseCase ne dipende
  getIt.registerLazySingleton<UserUseCase>(
    () => UserUseCase(getIt<UserRepository>()),
  );

  // TeamMember - Dipende da UserUseCase per creare membri tramite email
  getIt.registerLazySingleton<TeamMemberUseCase>(
    () => TeamMemberUseCase(
      getIt<TeamMemberRepository>(),
      userUseCase: getIt<UserUseCase>(),
    ),
  );

  // Sondage
  getIt.registerLazySingleton<SondageUseCase>(
    () => SondageUseCase(getIt<SondageRepository>()),
  );

  // Clocking
  getIt.registerLazySingleton<ClockingUseCase>(
    () => ClockingUseCase(getIt<ClockingRepository>()),
  );

  // Dashboard
  getIt.registerLazySingleton<DashboardUseCase>(
    () => DashboardUseCase(getIt<DashboardRepository>()),
  );
}

// ==================== BLOCS ====================

void _registerBlocs() {
  // Role - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<RoleBloc>(
    () => RoleBloc(roleUseCase: getIt<RoleUseCase>()),
  );

  // Team - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<TeamBloc>(
    () => TeamBloc(
      teamUseCase: getIt<TeamUseCase>(),
      teamLocalDataSource: getIt<TeamLocalDataSource>(),
    ),
  );

  // TeamMember - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<TeamMemberBloc>(
    () => TeamMemberBloc(teamMemberUseCase: getIt<TeamMemberUseCase>()),
  );

  // User - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<UserBloc>(
    () => UserBloc(userUseCase: getIt<UserUseCase>()),
  );

  // Sondage - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<SondageBloc>(
    () => SondageBloc(
      sondageUseCase: getIt<SondageUseCase>(),
      sondageLocalDataSource: getIt<SondageLocalDataSource>(),
    ),
  );

  // Clocking - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<ClockingBloc>(
    () => ClockingBloc(clockingUseCase: getIt<ClockingUseCase>()),
  );

  // Dashboard - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<DashboardBloc>(
    () => DashboardBloc(dashboardUseCase: getIt<DashboardUseCase>()),
  );

  // Notification services
  getIt.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService(),
  );
  getIt.registerLazySingleton<BackendAuthDataSource>(
    () => BackendAuthDataSource(),
  );
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      localNotifications: getIt<LocalNotificationService>(),
      backendAuth: getIt<BackendAuthDataSource>(),
    ),
  );
  getIt.registerLazySingleton<NotificationPreferencesCubit>(
    () => NotificationPreferencesCubit(
      backendAuth: getIt<BackendAuthDataSource>(),
      localNotificationService: getIt<LocalNotificationService>(),
    ),
  );
  getIt.registerLazySingleton<NotificationCenterCubit>(
    () => NotificationCenterCubit(
      backendAuth: getIt<BackendAuthDataSource>(),
      currentUserIdProvider: () => getIt<AuthBloc>().state.user.uid,
    ),
  );
  getIt.registerLazySingleton<TeamRealtimeCoordinator>(
    () => TeamRealtimeCoordinator(),
  );
  getIt.registerLazySingleton<SondageRealtimeCoordinator>(
    () => SondageRealtimeCoordinator(),
  );
  getIt.registerLazySingleton<ClockingRealtimeCoordinator>(
    () => ClockingRealtimeCoordinator(),
  );
  getIt.registerLazySingleton<ShiftRealtimeCoordinator>(
    () => ShiftRealtimeCoordinator(),
  );
}

// ==================== SHIFT ====================

void _registerShift() {
  getIt.registerLazySingleton<ShiftRemoteDataSource>(
    () => ShiftRemoteDataSource(),
  );
  getIt.registerLazySingleton<ShiftRepository>(
    () => ShiftRepositoryImpl(getIt<ShiftRemoteDataSource>()),
  );
  // ShiftBloc come LazySingleton per poter essere osservato da ShiftAlarmScheduler
  getIt.registerLazySingleton<ShiftBloc>(
    () => ShiftBloc(getIt<ShiftRepository>()),
  );
  getIt.registerLazySingleton<ShiftAlarmScheduler>(
    () => ShiftAlarmScheduler(
      shiftBloc: getIt<ShiftBloc>(),
      localNotifications: getIt<LocalNotificationService>(),
    ),
  );
  getIt.registerLazySingleton<ShiftOpenIntentController>(
    () => ShiftOpenIntentController(),
  );
}
