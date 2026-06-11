// role_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';

part 'role_event.dart';
part 'role_state.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final RoleUseCase roleUseCase;

  RoleBloc({required this.roleUseCase}) : super(RoleInitial()) {
    on<LoadRolesEvent>(_onLoadRoles);
    on<LoadRolesEventByTeamId>(_onLoadRolesByTeamId);
    on<LoadRoleByIdEvent>(_onLoadRoleById);
    on<CreateRoleEvent>(_onCreateRole);
    on<UpdateRoleEvent>(_onUpdateRole);
    on<DeleteRoleEvent>(_onDeleteRole);
  }

  Future<void> _onLoadRoles(
    LoadRolesEvent event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    try {
      final roles = await roleUseCase.getAllRoles();
      emit(RolesLoaded(roles));
    } catch (e) {
      emit(
        RoleError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the roles right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onLoadRolesByTeamId(
    LoadRolesEventByTeamId event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    try {
      final roles = await roleUseCase.getAllRolesByTeamId(event.teamId);
      emit(RolesLoaded(roles));
    } catch (e) {
      emit(
        RoleError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load the roles right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onLoadRoleById(
    LoadRoleByIdEvent event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    try {
      final role = await roleUseCase.getRoleById(event.id);
      if (role != null) {
        emit(RoleLoaded(role));
      } else {
        emit(RoleError('Role not found'));
      }
    } catch (e) {
      emit(
        RoleError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not load this role right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onCreateRole(
    CreateRoleEvent event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    try {
      final role = await roleUseCase.createRole(event.role);
      emit(RoleCreated(role));
      // Ricarica la lista dopo la creazione
      //add(LoadRolesEvent());
      add(LoadRolesEventByTeamId(event.teamId));
    } catch (e) {
      emit(
        RoleError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not create the role right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onUpdateRole(
    UpdateRoleEvent event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    try {
      final role = await roleUseCase.updateRole(event.role);
      emit(RoleUpdated(role));
      // Ricarica la lista dopo l'aggiornamento
      add(LoadRolesEventByTeamId(event.role.teamId));
    } catch (e) {
      emit(
        RoleError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not update the role right now.',
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteRole(
    DeleteRoleEvent event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    try {
      final success = await roleUseCase.deleteRole(event.id);
      if (success) {
        emit(RoleDeleted());
        // Ricarica la lista dopo l'eliminazione
        add(LoadRolesEventByTeamId(event.teamId));
      } else {
        emit(RoleError('We could not delete the role right now.'));
      }
    } catch (e) {
      emit(
        RoleError(
          AppErrorMessageResolver.resolve(
            e,
            fallback: 'We could not delete the role right now.',
          ),
        ),
      );
    }
  }
}
