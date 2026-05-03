import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';

/// Ascolta lo [ShiftBloc] e schedula / cancella le notifiche locali di allarme
/// ogni volta che i turni vengono caricati, creati, aggiornati o eliminati.
///
/// Dipende da [LocalNotificationService] (già inizializzato in main.dart).
class ShiftAlarmScheduler {
  ShiftAlarmScheduler({
    required ShiftBloc shiftBloc,
    required LocalNotificationService localNotifications,
  })  : _shiftBloc = shiftBloc,
        _localNotifications = localNotifications;

  final ShiftBloc _shiftBloc;
  final LocalNotificationService _localNotifications;
  StreamSubscription<ShiftState>? _subscription;

  /// Avvia l'ascolto degli stati del bloc.
  void start() {
    _subscription = _shiftBloc.stream.listen(_handleState);
    debugPrint('[ShiftAlarmScheduler] started');
  }

  /// Ferma l'ascolto.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('[ShiftAlarmScheduler] stopped');
  }

  void _handleState(ShiftState state) {
    if (state is ShiftAssignmentsLoaded) {
      _rescheduleAll(state.assignments);
    } else if (state is ShiftAssigned) {
      _scheduleOne(state.assignment);
    } else if (state is ShiftAssignmentUpdated) {
      // Cancella i vecchi allarmi e rischedula con i nuovi offset
      _cancelAndReschedule(state.assignment);
    } else if (state is ShiftAssignmentDeleted) {
      // Non abbiamo l'id qui — la cancellazione viene fatta in cancelShiftAlarms
      // Prima del delete event l'UI passa l'id, quindi non serve fare altro.
      // Se volessimo possiamo aggiungere l'id allo stato, ma per ora è ok così.
    }
  }

  /// Schedula allarmi per tutti i turni caricati.
  Future<void> _rescheduleAll(List<ShiftAssignmentEntity> assignments) async {
    for (final a in assignments) {
      await _scheduleOne(a);
    }
  }

  /// Schedula allarmi per un singolo turno.
  Future<void> _scheduleOne(ShiftAssignmentEntity assignment) async {
    if (assignment.alarmOffsets.isEmpty) return;

    final shiftStart = DateTime(
      assignment.shiftDate.year,
      assignment.shiftDate.month,
      assignment.shiftDate.day,
      assignment.startTime.hour,
      assignment.startTime.minute,
    );

    await _localNotifications.scheduleShiftAlarms(
      shiftId: assignment.id,
      profileName: assignment.profileName ?? '',
      shiftStart: shiftStart,
      alarmOffsets: assignment.alarmOffsets,
    );
  }

  /// Cancella gli allarmi precedenti e rischedula (per update).
  Future<void> _cancelAndReschedule(ShiftAssignmentEntity assignment) async {
    await _localNotifications.cancelShiftAlarms(
      shiftId: assignment.id,
      alarmOffsets: assignment.alarmOffsets,
    );
    await _scheduleOne(assignment);
  }

  /// Cancella tutti gli allarmi per un turno specifico (chiamato dall'UI prima del delete).
  Future<void> cancelForAssignment(ShiftAssignmentEntity assignment) async {
    await _localNotifications.cancelShiftAlarms(
      shiftId: assignment.id,
      alarmOffsets: assignment.alarmOffsets,
    );
  }
}
