part of 'clocking_bloc.dart';

abstract class ClockingEvent extends Equatable {
  const ClockingEvent();

  @override
  List<Object?> get props => [];
}

class LoadClockingRecordsEvent extends ClockingEvent {
  final String? teamId;

  const LoadClockingRecordsEvent({this.teamId});

  @override
  List<Object?> get props => [teamId];
}

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

class StartBreakEvent extends ClockingEvent {
  final String? teamId;
  final String? note;

  const StartBreakEvent({this.teamId, this.note});

  @override
  List<Object?> get props => [teamId, note];
}

class StopBreakEvent extends ClockingEvent {
  final String? teamId;
  final String? note;

  const StopBreakEvent({this.teamId, this.note});

  @override
  List<Object?> get props => [teamId, note];
}

class UpdateClockingRecordEvent extends ClockingEvent {
  final String id;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final int? totalBreakMinutes;
  final String? note;

  const UpdateClockingRecordEvent({
    required this.id,
    this.clockInAt,
    this.clockOutAt,
    this.totalBreakMinutes,
    this.note,
  });

  @override
  List<Object?> get props => [id, clockInAt, clockOutAt, totalBreakMinutes, note];
}

class DecommitClockingRecordEvent extends ClockingEvent {
  final String id;

  const DecommitClockingRecordEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CommitClockingRecordEvent extends ClockingEvent {
  final String id;

  const CommitClockingRecordEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteClockingRecordEvent extends ClockingEvent {
  final String id;

  const DeleteClockingRecordEvent(this.id);

  @override
  List<Object?> get props => [id];
}
