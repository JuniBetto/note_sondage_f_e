import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/ui/bloc/task_bloc.dart';

/// Ascolta il [TaskBloc] e schedula / cancella le notifiche locali di
/// promemoria ogni volta che un task viene creato, aggiornato o archiviato.
///
/// Rispecchia [ShiftAlarmScheduler]: stessa infrastruttura di allarme
/// (canali, tipo, feedback), stesso pattern di ascolto dello stream del bloc.
///
/// Dipende da [LocalNotificationService] (gia inizializzato in main.dart).
class TaskAlarmScheduler {
  TaskAlarmScheduler({
    required TaskBloc taskBloc,
    required LocalNotificationService localNotifications,
  }) : _taskBloc = taskBloc,
       _localNotifications = localNotifications;

  final TaskBloc _taskBloc;
  final LocalNotificationService _localNotifications;
  StreamSubscription<TaskState>? _subscription;
  bool _started = false;

  /// Avvia l'ascolto degli stati del bloc.
  void start() {
    if (_started) {
      debugPrint('[TaskAlarmScheduler] start skipped: already running');
      return;
    }
    _started = true;
    _subscription?.cancel();
    _subscription = _taskBloc.stream.listen((state) {
      unawaited(_guardedHandleState(state));
    });
    debugPrint('[TaskAlarmScheduler] started');
  }

  /// Ferma l'ascolto.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
    debugPrint('[TaskAlarmScheduler] stopped');
  }

  Future<void> _handleState(TaskState state) async {
    if (state is TaskCreated) {
      await _cancelAndReschedule(state.task);
    } else if (state is TaskUpdated) {
      await _cancelAndReschedule(state.task);
    } else if (state is TaskArchived) {
      await _localNotifications.cancelTaskAlarms(
        taskId: state.task.id,
        alarmOffsets: state.task.reminderOffsets,
      );
    } else if (state is TaskDeleted) {
      await _localNotifications.cancelTaskAlarms(
        taskId: state.task.id,
        alarmOffsets: state.task.reminderOffsets,
      );
    }
  }

  Future<void> _guardedHandleState(TaskState state) async {
    try {
      await _handleState(state);
    } catch (error, stack) {
      debugPrint(
        '[TaskAlarmScheduler] Unhandled scheduling error: $error\n$stack',
      );
    }
  }

  /// Cancella gli allarmi precedenti e rischedula in base allo stato attuale
  /// del task (creazione, modifica, cambio stato/assegnatario, ripristino).
  Future<void> _cancelAndReschedule(TaskEntity task) async {
    final anchorTime = task.reminderAnchorTime;
    if (task.isArchived ||
        task.reminderOffsets.isEmpty ||
        anchorTime == null) {
      await _localNotifications.cancelTaskAlarms(
        taskId: task.id,
        alarmOffsets: task.reminderOffsets,
      );
      return;
    }

    debugPrint(
      '[TaskAlarmScheduler] Scheduling ${task.id} at $anchorTime with offsets=${task.reminderOffsets}',
    );
    await _localNotifications.scheduleTaskAlarms(
      taskId: task.id,
      taskTitle: task.title,
      anchorTime: anchorTime,
      alarmOffsets: task.reminderOffsets,
    );
  }
}
