part of 'sondage_bloc.dart';

abstract class SondageState extends Equatable {
  const SondageState();

  @override
  List<Object?> get props => [];
}

class SondageInitial extends SondageState {}

class SondageLoading extends SondageState {}

// TODO: Decommentare quando SondageEntity sarà creata
/*
class SondagesLoaded extends SondageState {
  final List<SondageEntity> Sondages;

  const SondagesLoaded(this.Sondages);

  @override
  List<Object?> get props => [Sondages];
}

class SondageLoaded extends SondageState {
  final SondageEntity Sondage;

  const SondageLoaded(this.Sondage);

  @override
  List<Object?> get props => [Sondage];
}

class SondageCreated extends SondageState {
  final SondageEntity Sondage;

  const SondageCreated(this.Sondage);

  @override
  List<Object?> get props => [Sondage];
}

class SondageUpdated extends SondageState {
  final SondageEntity Sondage;

  const SondageUpdated(this.Sondage);

  @override
  List<Object?> get props => [Sondage];
}
*/

class SondageDeleted extends SondageState {}

class SondageError extends SondageState {
  final String message;

  const SondageError(this.message);

  @override
  List<Object?> get props => [message];
}
