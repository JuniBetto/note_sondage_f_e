// permission_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/permission/permission_use_case.dart';

part 'permission_event.dart';
part 'permission_state.dart';

class RoleBloc extends Bloc<PermissionEvent, PermissionState> {
  final PermissionUseCase permissionUseCase;

  RoleBloc({required this.permissionUseCase}) : super(PermissionInitial()) {
    on<LoadPermissionsEvent>(_onLoadPermissions);
    on<LoadPermissionByIdEvent>(_onLoadPermissionById);
    on<CreatePermissionEvent>(_onCreatePermission);
    on<UpdatePermissionEvent>(_onUpdatePermission);
    on<DeletePermissionEvent>(_onDeletePermission);
  }

  Future<void> _onLoadPermissions(
    LoadPermissionsEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(PermissionLoading());
    try {
      final permissions = await permissionUseCase.getAllPermissions();
      emit(PermissionsLoaded(permissions));
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }

  Future<void> _onLoadPermissionById(
    LoadPermissionByIdEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(PermissionLoading());
    try {
      final permission = await permissionUseCase.getPermissionById(event.id);
      emit(PermissionLoaded(permission));
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }

  Future<void> _onCreatePermission(
    CreatePermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(PermissionLoading());
    try {
      final permission = await permissionUseCase.createPermission(
        event.permission,
      );
      emit(PermissionCreated(permission));
      // Ricarica la lista dopo la creazione
      add(LoadPermissionsEvent());
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }

  Future<void> _onUpdatePermission(
    UpdatePermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(PermissionLoading());
    try {
      final permission = await permissionUseCase.updatePermission(
        event.id,
        event.permission,
      );
      emit(PermissionUpdated(permission));
      // Ricarica la lista dopo l'aggiornamento
      add(LoadPermissionsEvent());
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }

  Future<void> _onDeletePermission(
    DeletePermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(PermissionLoading());
    try {
      await permissionUseCase.deletePermission(event.id);
      emit(PermissionDeleted());
      // Ricarica la lista dopo l'eliminazione
      add(LoadPermissionsEvent());
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }
}
