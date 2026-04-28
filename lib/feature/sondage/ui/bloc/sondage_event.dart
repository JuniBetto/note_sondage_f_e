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
