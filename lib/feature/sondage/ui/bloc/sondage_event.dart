part of 'sondage_bloc.dart';

abstract class SondageEvent extends Equatable {
  const SondageEvent();

  @override
  List<Object?> get props => [];
}

class LoadSondagesEvent extends SondageEvent {}

class LoadSondagesByUserIdEvent extends SondageEvent {
  final String userId;

  const LoadSondagesByUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadSondageByIdEvent extends SondageEvent {
  final String id;

  const LoadSondageByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateSondageEvent extends SondageEvent {
  final SondageEntity sondage;

  const CreateSondageEvent(this.sondage);

  @override
  List<Object?> get props => [sondage];
}

class UpdateSondageEvent extends SondageEvent {
  final SondageEntity sondage;

  const UpdateSondageEvent(this.sondage);

  @override
  List<Object?> get props => [sondage];
}

class DeleteSondageEvent extends SondageEvent {
  final String id;

  const DeleteSondageEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class PublishSondageEvent extends SondageEvent {
  final String id;

  const PublishSondageEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CloseSondageEvent extends SondageEvent {
  final String id;

  const CloseSondageEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ReopenSondageEvent extends SondageEvent {
  final String id;

  const ReopenSondageEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class VoteSondageEvent extends SondageEvent {
  final String sondageId;
  final String optionId;

  const VoteSondageEvent(this.sondageId, this.optionId);

  @override
  List<Object?> get props => [sondageId, optionId];
}

class ResetSondageCacheEvent extends SondageEvent {
  const ResetSondageCacheEvent();
}

class _SondageCreateCommittedEvent extends SondageEvent {
  final String temporaryId;
  final SondageEntity sondage;

  const _SondageCreateCommittedEvent(this.temporaryId, this.sondage);

  @override
  List<Object?> get props => [temporaryId, sondage];
}

class _SondageUpdateCommittedEvent extends SondageEvent {
  final String sondageId;
  final SondageEntity sondage;

  const _SondageUpdateCommittedEvent(this.sondageId, this.sondage);

  @override
  List<Object?> get props => [sondageId, sondage];
}

class _SondageDeleteCommittedEvent extends SondageEvent {
  final String sondageId;

  const _SondageDeleteCommittedEvent(this.sondageId);

  @override
  List<Object?> get props => [sondageId];
}

class _SondageMutationFailedEvent extends SondageEvent {
  final String message;
  final List<SondageEntity> rollbackSondages;
  final Set<String> syncingIdsToClear;

  const _SondageMutationFailedEvent({
    required this.message,
    required this.rollbackSondages,
    required this.syncingIdsToClear,
  });

  @override
  List<Object?> get props => [message, rollbackSondages, syncingIdsToClear];
}
