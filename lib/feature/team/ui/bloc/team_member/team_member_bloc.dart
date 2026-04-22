// team_member_bloc.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

part 'team_member_event.dart';
part 'team_member_state.dart';

class TeamMemberBloc extends Bloc<TeamMemberEvent, TeamMemberState> {
  final TeamMemberUseCase teamMemberUseCase;

  TeamMemberBloc({required this.teamMemberUseCase})
    : super(TeamMemberInitial()) {
    on<LoadTeamMembersEvent>(_onLoadMembers);
    on<LoadTeamMembersByTeamIdEvent>(_onLoadMembersByTeamId);
    on<LoadTeamMemberByIdEvent>(_onLoadMemberById);
    on<CreateTeamMemberEvent>(_onCreateMember);
    on<CreateTeamMemberByEmailEvent>(_onCreateMemberByEmail);
    on<UpdateTeamMemberEvent>(_onUpdateMember);
    on<DeleteTeamMemberEvent>(_onDeleteMember);
    on<InviteTeamMemberEvent>(_onInviteMember);
    on<UploadTeamMemberImageEvent>(_onUploadImage);
    on<LoadTeamInvitationsEvent>(_onLoadInvitations);
    on<CancelTeamInvitationEvent>(_onCancelInvitation);
  }

  Future<void> _onLoadMembers(
    LoadTeamMembersEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final members = await teamMemberUseCase.getAllMembers();
      emit(TeamMembersLoaded(members));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onLoadMembersByTeamId(
    LoadTeamMembersByTeamIdEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    // Don't emit TeamMemberLoading here — it would reset the UI
    // for all teams while loading members for just one team.
    // The UI already shows previously loaded members.
    try {
      final members = await teamMemberUseCase.getAllMembersByTeamId(
        event.teamId,
      );
      emit(TeamMembersLoaded(members));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onLoadMemberById(
    LoadTeamMemberByIdEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final member = await teamMemberUseCase.getMemberById(event.id);
      if (member != null) {
        emit(TeamMemberLoaded(member));
      } else {
        emit(const TeamMemberError('Team member not found'));
      }
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onCreateMember(
    CreateTeamMemberEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      // 1. Crea il member
      var member = await teamMemberUseCase.createMember(event.member);

      // 2. Se c'è un'immagine da caricare, fallo
      if (event.member.hasImageToUpload && member.id != null) {
        member = await teamMemberUseCase.uploadProfileImage(
          memberId: member.id!,
          imageFile: event.member.imageFile,
          imageBytes: event.member.imageBytes,
          fileName: event.member.fileName,
        );
      }

      emit(TeamMemberCreated(member));
      // Ricarica la lista dopo la creazione
      add(LoadTeamMembersByTeamIdEvent(event.teamId));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  /// Crea un TeamMember usando l'email.
  /// Se l'utente non esiste, viene creato con is_active = false.
  /// Se imageFile o imageBytes sono forniti, l'immagine viene caricata dopo la creazione.
  Future<void> _onCreateMemberByEmail(
    CreateTeamMemberByEmailEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final bool hasImage = event.imageFile != null || event.imageBytes != null;

      TeamMemberEntity member;

      if (hasImage) {
        // Usa il metodo che crea e carica l'immagine
        member = await teamMemberUseCase.createMemberWithImage(
          email: event.email,
          teamId: event.teamId,
          roleId: event.roleId,
          status: event.status,
          imageFile: event.imageFile,
          imageBytes: event.imageBytes,
          fileName: event.fileName,
        );
      } else {
        // Crea solo il membro senza immagine
        member = await teamMemberUseCase.createMemberByEmail(
          email: event.email,
          teamId: event.teamId,
          roleId: event.roleId,
          status: event.status,
        );
      }

      emit(TeamMemberCreated(member));
      // Ricarica la lista dopo la creazione
      add(LoadTeamMembersByTeamIdEvent(event.teamId));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onUpdateMember(
    UpdateTeamMemberEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final member = await teamMemberUseCase.updateMember(event.member);
      emit(TeamMemberUpdated(member));
      // Ricarica la lista dopo l'aggiornamento
      add(LoadTeamMembersByTeamIdEvent(event.teamId));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onDeleteMember(
    DeleteTeamMemberEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final success = await teamMemberUseCase.deleteMember(event.id);
      if (success) {
        emit(TeamMemberDeleted());
        // Ricarica la lista dopo l'eliminazione
        add(LoadTeamMembersByTeamIdEvent(event.teamId));
      } else {
        emit(const TeamMemberError('Failed to delete team member'));
      }
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onInviteMember(
    InviteTeamMemberEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final success = await teamMemberUseCase.inviteMember(
        event.teamId,
        event.email,
        event.roleId,
      );
      if (success) {
        emit(TeamMemberInvited());
        // Ricarica la lista dopo l'invito
        add(LoadTeamMembersByTeamIdEvent(event.teamId));
      } else {
        emit(const TeamMemberError('Failed to invite team member'));
      }
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  /// Carica/aggiorna l'immagine profilo di un TeamMember esistente.
  Future<void> _onUploadImage(
    UploadTeamMemberImageEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    emit(TeamMemberLoading());
    try {
      final member = await teamMemberUseCase.uploadProfileImage(
        memberId: event.memberId,
        imageFile: event.imageFile,
        imageBytes: event.imageBytes,
        fileName: event.fileName,
      );
      emit(TeamMemberUpdated(member));
      add(LoadTeamMembersByTeamIdEvent(event.teamId));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onLoadInvitations(
    LoadTeamInvitationsEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    try {
      final invitations = await teamMemberUseCase.getPendingInvitations(event.teamId);
      emit(TeamInvitationsLoaded(invitations));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }

  Future<void> _onCancelInvitation(
    CancelTeamInvitationEvent event,
    Emitter<TeamMemberState> emit,
  ) async {
    try {
      await teamMemberUseCase.cancelInvitation(event.teamId, event.invitationId);
      emit(TeamInvitationCancelled());
      add(LoadTeamInvitationsEvent(event.teamId));
    } catch (e) {
      emit(TeamMemberError(e.toString()));
    }
  }
}
