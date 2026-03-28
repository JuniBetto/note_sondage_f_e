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

// TODO: Decommentare quando SondageEntity sarà creata
/*
class CreateSondageEvent extends SondageEvent {
  final SondageEntity Sondage;
  final String? userId;

  const CreateSondageEvent(this.Sondage, {this.userId});

  @override
  List<Object?> get props => [Sondage, userId];
}

class UpdateSondageEvent extends SondageEvent {
  final SondageUpdate Sondage;
  //final String? userId;

  const UpdateSondageEvent(this.Sondage);

  @override
  List<Object?> get props => [Sondage];
}
*/

class DeleteSondageEvent extends SondageEvent {
  final String id;
  final String? userId;

  const DeleteSondageEvent(this.id, {this.userId});

  @override
  List<Object?> get props => [id, userId];
}
