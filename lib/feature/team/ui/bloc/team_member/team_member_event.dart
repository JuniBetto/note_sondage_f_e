part of 'team_member_bloc.dart';

abstract class TeamMemberEvent extends Equatable {
  const TeamMemberEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamMembersEvent extends TeamMemberEvent {}

class LoadTeamMembersByTeamIdEvent extends TeamMemberEvent {
  final String teamId;

  const LoadTeamMembersByTeamIdEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class LoadTeamMemberByIdEvent extends TeamMemberEvent {
  final String id;

  const LoadTeamMemberByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateTeamMemberEvent extends TeamMemberEvent {
  final TeamMemberEntity member;
  final String teamId;

  const CreateTeamMemberEvent(this.member, {required this.teamId});

  @override
  List<Object?> get props => [member, teamId];
}

class UpdateTeamMemberEvent extends TeamMemberEvent {
  final TeamMemberEntity member;
  final String teamId;

  const UpdateTeamMemberEvent(this.member, {required this.teamId});

  @override
  List<Object?> get props => [member, teamId];
}

class DeleteTeamMemberEvent extends TeamMemberEvent {
  final String id;
  final String teamId;

  const DeleteTeamMemberEvent(this.id, {required this.teamId});

  @override
  List<Object?> get props => [id, teamId];
}

class InviteTeamMemberEvent extends TeamMemberEvent {
  final String teamId;
  final String email;
  final String roleId;

  const InviteTeamMemberEvent({
    required this.teamId,
    required this.email,
    required this.roleId,
  });

  @override
  List<Object?> get props => [teamId, email, roleId];
}

class LoadTeamInvitationsEvent extends TeamMemberEvent {
  final String teamId;
  const LoadTeamInvitationsEvent(this.teamId);
  @override
  List<Object?> get props => [teamId];
}

class CancelTeamInvitationEvent extends TeamMemberEvent {
  final String teamId;
  final String invitationId;
  const CancelTeamInvitationEvent({
    required this.teamId,
    required this.invitationId,
  });
  @override
  List<Object?> get props => [teamId, invitationId];
}

/// Evento per creare un TeamMember usando l'email.
/// Se l'utente non esiste, viene creato con is_active = false.
/// Se imageFile o imageBytes sono forniti, l'immagine viene caricata dopo la creazione.
class CreateTeamMemberByEmailEvent extends TeamMemberEvent {
  final String email;
  final String teamId;
  final String roleId;
  final UserStatus status;

  /// Avatar image file (for mobile)
  final File? imageFile;

  /// Avatar image bytes (for web)
  final Uint8List? imageBytes;

  /// File name (required when using imageBytes)
  final String? fileName;

  const CreateTeamMemberByEmailEvent({
    required this.email,
    required this.teamId,
    required this.roleId,
    this.status = UserStatus.pending,
    this.imageFile,
    this.imageBytes,
    this.fileName,
  });

  @override
  List<Object?> get props => [
    email,
    teamId,
    roleId,
    status,
    imageFile,
    imageBytes,
    fileName,
  ];
}

/// Evento per caricare/aggiornare l'immagine profilo di un TeamMember esistente.
class UploadTeamMemberImageEvent extends TeamMemberEvent {
  final String memberId;
  final String teamId;

  /// Avatar image file (for mobile)
  final File? imageFile;

  /// Avatar image bytes (for web)
  final Uint8List? imageBytes;

  /// File name (required when using imageBytes)
  final String? fileName;

  const UploadTeamMemberImageEvent({
    required this.memberId,
    required this.teamId,
    this.imageFile,
    this.imageBytes,
    this.fileName,
  });

  @override
  List<Object?> get props => [
    memberId,
    teamId,
    imageFile,
    imageBytes,
    fileName,
  ];
}
