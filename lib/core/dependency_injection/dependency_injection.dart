import 'package:get_it/get_it.dart';
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
import 'package:note_sondage/feature/team/ui/bloc/permission/permission_bloc.dart'
    hide RoleBloc;
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/user/user_bloc.dart';

final getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setup() async {
  _registerDataSources();
  _registerRepositories();
  _registerUseCases();
  _registerBlocs();
}

// ==================== DATA SOURCES ====================

void _registerDataSources() {
  // Role
  getIt.registerLazySingleton<RoleRemoteDataSource>(
    () => RoleRemoteDataSource(),
  );

  // Team
  getIt.registerLazySingleton<TeamRemoteDataSource>(
    () => TeamRemoteDataSource(),
  );

  // TeamMember
  getIt.registerLazySingleton<TeamMemberRemoteDataSource>(
    () => TeamMemberRemoteDataSource(),
  );

  // User
  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSource(),
  );
}

// ==================== REPOSITORIES ====================

void _registerRepositories() {
  // Role
  getIt.registerLazySingleton<RoleRepository>(
    () => RoleRepositoryImpl(getIt<RoleRemoteDataSource>()),
  );

  // Team
  getIt.registerLazySingleton<TeamRepository>(
    () => TeamRepositoryImpl(getIt<TeamRemoteDataSource>()),
  );

  // TeamMember
  getIt.registerLazySingleton<TeamMemberRepository>(
    () => TeamMemberRepositoryImpl(getIt<TeamMemberRemoteDataSource>()),
  );

  // User
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: getIt<UserRemoteDataSource>()),
  );
}

// ==================== USE CASES ====================

void _registerUseCases() {
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
}

// ==================== BLOCS ====================

void _registerBlocs() {
  // Role - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<RoleBloc>(
    () => RoleBloc(roleUseCase: getIt<RoleUseCase>()),
  );

  // Team - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<TeamBloc>(
    () => TeamBloc(teamUseCase: getIt<TeamUseCase>()),
  );

  // TeamMember - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<TeamMemberBloc>(
    () => TeamMemberBloc(teamMemberUseCase: getIt<TeamMemberUseCase>()),
  );

  // User - Singleton per condividere lo stato tra widget
  getIt.registerLazySingleton<UserBloc>(
    () => UserBloc(userUseCase: getIt<UserUseCase>()),
  );
}
