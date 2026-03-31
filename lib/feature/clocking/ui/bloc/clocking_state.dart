part of 'clocking_bloc.dart';

abstract class ClockingState extends Equatable {
  const ClockingState();

  @override
  List<Object?> get props => [];
}

class ClockingInitial extends ClockingState {}

class ClockingLoading extends ClockingState {}

class ClockingRecordsLoaded extends ClockingState {
  final List<ClockingRecordEntity> records;
  final DateTime _timestamp;

  ClockingRecordsLoaded(this.records) : _timestamp = DateTime.now();

  @override
  List<Object?> get props => [records, _timestamp];
}

class ClockingActionSuccess extends ClockingState {
  final ClockingRecordEntity record;

  const ClockingActionSuccess(this.record);

  @override
  List<Object?> get props => [record];
}

class ClockingDeleted extends ClockingState {}

class ClockingError extends ClockingState {
  final String message;

  const ClockingError(this.message);

  @override
  List<Object?> get props => [message];
}
