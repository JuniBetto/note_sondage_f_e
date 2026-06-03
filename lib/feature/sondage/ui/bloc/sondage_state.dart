part of 'sondage_bloc.dart';

abstract class SondageState extends Equatable {
  const SondageState();

  @override
  List<Object?> get props => [];
}

class SondageInitial extends SondageState {}

class SondageLoading extends SondageState {}

class SondagesLoaded extends SondageState {
  final List<SondageEntity> sondages;
  final DateTime _timestamp;

  SondagesLoaded(this.sondages) : _timestamp = DateTime.now();

  @override
  List<Object?> get props => [sondages, _timestamp];
}

class SondageLoaded extends SondageState {
  final SondageEntity sondage;

  const SondageLoaded(this.sondage);

  @override
  List<Object?> get props => [sondage];
}

class SondageCreated extends SondageState {
  final SondageEntity sondage;

  const SondageCreated(this.sondage);

  @override
  List<Object?> get props => [sondage];
}

class SondageUpdated extends SondageState {
  final SondageEntity sondage;

  const SondageUpdated(this.sondage);

  @override
  List<Object?> get props => [sondage];
}

class SondageDeleted extends SondageState {}

class SondageActionSuccess extends SondageState {
  final SondageEntity sondage;

  const SondageActionSuccess(this.sondage);

  @override
  List<Object?> get props => [sondage];
}

class SondageError extends SondageState {
  final String message;

  const SondageError(this.message);

  @override
  List<Object?> get props => [message];
}
