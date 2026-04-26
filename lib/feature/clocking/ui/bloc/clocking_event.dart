part of 'clocking_bloc.dart';

abstract class ClockingEvent extends Equatable {
  const ClockingEvent();

  @override
  List<Object?> get props => [];
}

class LoadClockingRecordsEvent extends ClockingEvent {}

class LoadClockingByDateEvent extends ClockingEvent {
  final DateTime date;

  const LoadClockingByDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class LoadClockingByUserIdEvent extends ClockingEvent {
  final String userId;

  const LoadClockingByUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadClockingByTeamIdEvent extends ClockingEvent {
  final String teamId;

  const LoadClockingByTeamIdEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class ClockInEvent extends ClockingEvent {
  final String teamId;
  final String? note;

  const ClockInEvent({required this.teamId, this.note});

  @override
  List<Object?> get props => [teamId, note];
}

class ClockOutEvent extends ClockingEvent {
  final String? teamId;
  final String? note;

  const ClockOutEvent({this.teamId, this.note});

  @override
  List<Object?> get props => [teamId, note];
}

class DeleteClockingRecordEvent extends ClockingEvent {
  final String id;

  const DeleteClockingRecordEvent(this.id);

  @override
  List<Object?> get props => [id];
}
