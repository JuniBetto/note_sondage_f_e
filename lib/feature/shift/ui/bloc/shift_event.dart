import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ShiftEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadShiftProfilesEvent extends ShiftEvent {}

class CreateShiftProfileEvent extends ShiftEvent {
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final List<int> alarmOffsets;
  final String? color;
  final bool isPublic;

  CreateShiftProfileEvent({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.alarmOffsets,
    this.color,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [
    name,
    startTime,
    endTime,
    overnight,
    alarmOffsets,
    color,
    isPublic,
  ];
}

class UpdateShiftProfileEvent extends ShiftEvent {
  final String profileId;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final List<int> alarmOffsets;
  final String? color;
  final bool isPublic;

  UpdateShiftProfileEvent({
    required this.profileId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.alarmOffsets,
    this.color,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [profileId, name, isPublic];
}

class DeleteShiftProfileEvent extends ShiftEvent {
  final String profileId;
  DeleteShiftProfileEvent(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

class LoadShiftAssignmentsEvent extends ShiftEvent {
  final DateTime from;
  final DateTime to;
  LoadShiftAssignmentsEvent({required this.from, required this.to});

  @override
  List<Object?> get props => [from, to];
}

class AssignShiftEvent extends ShiftEvent {
  final DateTime shiftDate;
  final String? profileId;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool? overnight;
  final String? note;
  final List<int>? alarmOffsets;
  final bool isPublic;
  final String? teamId;
  final String? teamShiftGroupId;

  /// Firebase UID of the target user. Null = assign to the authenticated caller.
  final String? targetUserId;

  AssignShiftEvent({
    required this.shiftDate,
    this.profileId,
    this.startTime,
    this.endTime,
    this.overnight,
    this.note,
    this.alarmOffsets,
    this.isPublic = false,
    this.teamId,
    this.teamShiftGroupId,
    this.targetUserId,
  });

  @override
  List<Object?> get props => [
    shiftDate,
    profileId,
    isPublic,
    teamId,
    teamShiftGroupId,
    targetUserId,
  ];
}

class UpdateShiftAssignmentEvent extends ShiftEvent {
  final String assignmentId;
  final String? profileId;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool? overnight;
  final String? note;
  final List<int>? alarmOffsets;
  final bool isPublic;
  final String? teamId;
  final String? teamShiftGroupId;

  /// Firebase UID of the new target user. Null = keep the existing owner.
  final String? targetUserId;

  UpdateShiftAssignmentEvent({
    required this.assignmentId,
    this.profileId,
    this.startTime,
    this.endTime,
    this.overnight,
    this.note,
    this.alarmOffsets,
    this.isPublic = false,
    this.teamId,
    this.teamShiftGroupId,
    this.targetUserId,
  });

  @override
  List<Object?> get props => [
    assignmentId,
    isPublic,
    teamId,
    teamShiftGroupId,
    targetUserId,
  ];
}

class DeleteShiftAssignmentEvent extends ShiftEvent {
  final String assignmentId;
  DeleteShiftAssignmentEvent(this.assignmentId);

  @override
  List<Object?> get props => [assignmentId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ShiftState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftProfilesLoaded extends ShiftState {
  final List<ShiftProfileEntity> profiles;
  ShiftProfilesLoaded(this.profiles);

  @override
  List<Object?> get props => [profiles];
}

class ShiftProfileCreated extends ShiftState {
  final ShiftProfileEntity profile;
  ShiftProfileCreated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ShiftProfileUpdated extends ShiftState {
  final ShiftProfileEntity profile;
  ShiftProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ShiftProfileDeleted extends ShiftState {
  final String profileId;
  ShiftProfileDeleted(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

class ShiftAssignmentsLoaded extends ShiftState {
  final List<ShiftAssignmentEntity> assignments;
  ShiftAssignmentsLoaded(this.assignments);

  @override
  List<Object?> get props => [assignments];
}

class ShiftAssigned extends ShiftState {
  final ShiftAssignmentEntity assignment;
  ShiftAssigned(this.assignment);

  @override
  List<Object?> get props => [assignment];
}

class ShiftAssignmentUpdated extends ShiftState {
  final ShiftAssignmentEntity assignment;
  ShiftAssignmentUpdated(this.assignment);

  @override
  List<Object?> get props => [assignment];
}

class ShiftAssignmentDeleted extends ShiftState {
  final String assignmentId;
  ShiftAssignmentDeleted(this.assignmentId);

  @override
  List<Object?> get props => [assignmentId];
}

class ShiftError extends ShiftState {
  final String message;
  ShiftError(this.message);

  @override
  List<Object?> get props => [message];
}
