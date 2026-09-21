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

  /// Firma (data di ancoraggio + offset + titolo) dell'ultima schedulazione
  /// riuscita per ciascun task, usata da [_cancelAndReschedule] per capire
  /// se rischedulare è davvero necessario. Vedi il commento li' per il
  /// perche'.
  final Map<String, String> _lastScheduledSignature = <String, String>{};

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

  /// Re-applies local reminders from a freshly fetched server snapshot.
  Future<void> syncTasks(Iterable<TaskEntity> tasks) async {
    for (final task in tasks) {
      try {
        await _cancelAndReschedule(task);
      } catch (error, stack) {
        debugPrint(
          '[TaskAlarmScheduler] Failed to sync task ${task.id}: $error\n$stack',
        );
      }
    }
  }

  /// Ferma l'ascolto.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
    _lastScheduledSignature.clear();
    debugPrint('[TaskAlarmScheduler] stopped');
  }

  Future<void> _handleState(TaskState state) async {
    if (state is TaskCreated) {
      await _cancelAndReschedule(state.task);
    } else if (state is TaskUpdated) {
      await _cancelAndReschedule(state.task);
    } else if (state is TaskArchived) {
      _lastScheduledSignature.remove(state.task.id);
      await _localNotifications.cancelTaskAlarms(
        taskId: state.task.id,
        alarmOffsets: state.task.reminderOffsets,
      );
    } else if (state is TaskDeleted) {
      _lastScheduledSignature.remove(state.task.id);
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
  ///
  /// [syncTasks] richiama questo metodo per ogni task ad ogni ricaricamento
  /// della lista (apertura schermata, pull-to-refresh, dopo un salvataggio,
  /// eventi realtime...), non solo quando qualcosa e' davvero cambiato.
  /// [LocalNotificationService.scheduleTaskAlarms] cancella sempre prima
  /// l'allarme esistente e lo rischedula solo se l'orario calcolato e'
  /// ancora nel futuro: se un resync "a vuoto" capita esattamente dopo che
  /// un allarme e' scattato ma prima che il sistema l'abbia consegnato,
  /// cancellava un allarme gia' armato e valido senza piu' rischedularlo,
  /// facendolo sparire nel nulla. Per questo si rischedula solo se la
  /// configurazione (data di ancoraggio, offset, titolo) e' davvero
  /// cambiata dall'ultima schedulazione riuscita.
  Future<void> _cancelAndReschedule(TaskEntity task) async {
    final anchorTime = task.reminderAnchorTime;
    if (task.isArchived || task.reminderOffsets.isEmpty || anchorTime == null) {
      _lastScheduledSignature.remove(task.id);
      await _localNotifications.cancelTaskAlarms(
        taskId: task.id,
        alarmOffsets: task.reminderOffsets,
      );
      return;
    }

    // Le notifiche task possono essere disattivate/riattivate da un toggle
    // (vedi NotificationPreferencesCubit) senza passare da qui: se sono
    // disattivate non ci fidiamo mai della cache, cosi' che riattivarle
    // faccia ripartire la schedulazione al prossimo sync invece di restare
    // bloccata perche' la firma risulta "gia' fatta".
    final notificationsEnabled = await _localNotifications
        .areTaskNotificationsEnabled();
    final signature = notificationsEnabled
        ? _signatureFor(
            anchorTime: anchorTime,
            offsets: task.reminderOffsets,
            title: task.title,
          )
        : null;
    if (signature != null && _lastScheduledSignature[task.id] == signature) {
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
    if (signature != null) {
      _lastScheduledSignature[task.id] = signature;
    }
  }

  String _signatureFor({
    required DateTime anchorTime,
    required List<int> offsets,
    required String title,
  }) => '${anchorTime.toIso8601String()}|${offsets.join(',')}|$title';
}
