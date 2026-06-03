part of 'clocking_bloc.dart';

abstract class ClockingState extends Equatable {
  const ClockingState();

  @override
  List<Object?> get props => [];
}

class ClockingInitial extends ClockingState {}

class ClockingLoading extends ClockingState {}

class ClockingActionInProgress extends ClockingState {
  final List<ClockingRecordEntity> myRecords;
  final List<ClockingRecordEntity> teamRecords;
  final String? selectedTeamId;
  final Set<String> syncingRecordIds;

  const ClockingActionInProgress({
    required this.myRecords,
    required this.teamRecords,
    required this.selectedTeamId,
    required this.syncingRecordIds,
  });

  @override
  List<Object?> get props => [
    myRecords,
    teamRecords,
    selectedTeamId,
    syncingRecordIds,
  ];
}

class ClockingRecordsLoaded extends ClockingState {
  final List<ClockingRecordEntity> myRecords;
  final List<ClockingRecordEntity> teamRecords;
  final String? selectedTeamId;
  final Set<String> syncingRecordIds;
  final DateTime _timestamp;

  ClockingRecordsLoaded({
    required this.myRecords,
    required this.teamRecords,
    required this.selectedTeamId,
    required this.syncingRecordIds,
  }) : _timestamp = DateTime.now();

  @override
  List<Object?> get props => [
    myRecords,
    teamRecords,
    selectedTeamId,
    syncingRecordIds,
    _timestamp,
  ];
}

class ClockingActionSuccess extends ClockingState {
  final ClockingRecordEntity record;
  final List<ClockingRecordEntity> myRecords;
  final List<ClockingRecordEntity> teamRecords;
  final String? selectedTeamId;
  final Set<String> syncingRecordIds;

  const ClockingActionSuccess({
    required this.record,
    required this.myRecords,
    required this.teamRecords,
    required this.selectedTeamId,
    required this.syncingRecordIds,
  });

  @override
  List<Object?> get props => [
    record,
    myRecords,
    teamRecords,
    selectedTeamId,
    syncingRecordIds,
  ];
}

class ClockingDeleted extends ClockingState {}

class ClockingError extends ClockingState {
  final String message;

  const ClockingError(this.message);

  @override
  List<Object?> get props => [message];
}
