// user_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/user/user_use_case.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserUseCase userUseCase;

  UserBloc({required this.userUseCase}) : super(UserInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<LoadUserByIdEvent>(_onLoadUserById);
    on<LoadUserByEmailEvent>(_onLoadUserByEmail);
    on<GetOrCreateUserByEmailEvent>(_onGetOrCreateUserByEmail);
    on<CreateUserEvent>(_onCreateUser);
    on<CreateInactiveUserEvent>(_onCreateInactiveUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<LoadUserByTeamIdEvent>(_onLoadUsersByTeamId);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final users = await userUseCase.getAllUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadUserById(
    LoadUserByIdEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userUseCase.getUserById(event.id);
      if (user != null) {
        emit(UserLoaded(user));
      } else {
        emit(const UserError('User not found'));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadUserByEmail(
    LoadUserByEmailEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userUseCase.getUserByEmail(event.email);
      if (user != null) {
        emit(UserLoaded(user));
      } else {
        emit(UserNotFound(event.email));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Cerca un utente per email, se non esiste lo crea con is_active = false
  Future<void> _onGetOrCreateUserByEmail(
    GetOrCreateUserByEmailEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userUseCase.getOrCreateUserByEmail(event.email);
      emit(UserFoundOrCreated(user, wasCreated: user.fullName.isEmpty));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userUseCase.createUser(event.user);
      emit(UserCreated(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onCreateInactiveUser(
    CreateInactiveUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userUseCase.createInactiveUser(event.email);
      emit(UserCreated(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userUseCase.updateUser(event.user);
      emit(UserUpdated(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      await userUseCase.deleteUser(event.id);
      emit(UserDeleted());
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadUsersByTeamId(
    LoadUserByTeamIdEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final users = await userUseCase.getAllUsersByTeamId(event.teamId);
      emit(UsersUpdateLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
