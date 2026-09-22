import 'package:flutter/foundation.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';

/// Schedula / cancella le notifiche locali di promemoria per gli eventi.
///
/// A differenza di [TaskAlarmScheduler] (che ascolta [TaskBloc], perche'
/// esiste un bloc dedicato per i task), il feature "event" non ha un bloc
/// proprio: [EventWorkspace] gestisce lo stato con `setState` e chiama
/// [EventUseCase] direttamente. Questo scheduler e' quindi puramente "pull":
/// e' [syncEvents] — richiamato dopo ogni fetch/creazione/modifica/
/// archiviazione/cancellazione in `EventWorkspace` — a fare da unico punto
/// di ingresso, sia per rischedulare gli eventi ancora presenti sia per
/// cancellare gli allarmi di quelli spariti dall'ultima sync (cancellati o
/// non piu' visibili all'utente).
///
/// Dipende da [LocalNotificationService] (gia inizializzato in main.dart).
class EventAlarmScheduler {
  EventAlarmScheduler({required LocalNotificationService localNotifications})
    : _localNotifications = localNotifications;

  final LocalNotificationService _localNotifications;
  bool _started = false;

  /// Firma (data di ancoraggio + offset + titolo) dell'ultima schedulazione
  /// riuscita per ciascun event, usata per capire se rischedulare e' davvero
  /// necessario — stesso motivo di [TaskAlarmScheduler._lastScheduledSignature].
  final Map<String, String> _lastScheduledSignature = <String, String>{};

  /// Offsets usati per l'ultima schedulazione riuscita di ciascun event —
  /// servono a [syncEvents] per poter cancellare correttamente gli allarmi
  /// di un event che e' sparito dalla lista (cancellato lato server, o non
  /// piu' visibile), quando l'entity stessa non e' piu' disponibile.
  final Map<String, List<int>> _lastScheduledOffsets = <String, List<int>>{};

  void start() {
    _started = true;
    debugPrint('[EventAlarmScheduler] started');
  }

  void stop() {
    _started = false;
    _lastScheduledSignature.clear();
    _lastScheduledOffsets.clear();
    debugPrint('[EventAlarmScheduler] stopped');
  }

  /// Re-applies local reminders from a freshly fetched server snapshot.
  /// Also cancels alarms for any event that was tracked before but is no
  /// longer present in [events] (deleted, or no longer visible to the user).
  Future<void> syncEvents(Iterable<EventEntity> events) async {
    if (!_started) {
      return;
    }
    final seenIds = <String>{};
    for (final event in events) {
      seenIds.add(event.id);
      try {
        await _cancelAndReschedule(event);
      } catch (error, stack) {
        debugPrint(
          '[EventAlarmScheduler] Failed to sync event ${event.id}: $error\n$stack',
        );
      }
    }

    final staleIds = _lastScheduledSignature.keys
        .where((id) => !seenIds.contains(id))
        .toList(growable: false);
    for (final staleId in staleIds) {
      final lastOffsets = _lastScheduledOffsets[staleId] ?? const <int>[];
      _lastScheduledSignature.remove(staleId);
      _lastScheduledOffsets.remove(staleId);
      if (lastOffsets.isNotEmpty) {
        await _localNotifications.cancelEventAlarms(
          eventId: staleId,
          alarmOffsets: lastOffsets,
        );
      }
    }
  }

  Future<void> _cancelAndReschedule(EventEntity event) async {
    final anchorTime = event.reminderAnchorTime;
    if (event.isArchived ||
        event.reminderOffsets.isEmpty ||
        anchorTime == null) {
      _lastScheduledSignature.remove(event.id);
      final previousOffsets =
          _lastScheduledOffsets.remove(event.id) ?? event.reminderOffsets;
      await _localNotifications.cancelEventAlarms(
        eventId: event.id,
        alarmOffsets: previousOffsets,
      );
      return;
    }

    final notificationsEnabled = await _localNotifications
        .areEventNotificationsEnabled();
    final signature = notificationsEnabled
        ? _signatureFor(
            anchorTime: anchorTime,
            offsets: event.reminderOffsets,
            title: event.title,
          )
        : null;
    if (signature != null && _lastScheduledSignature[event.id] == signature) {
      return;
    }

    debugPrint(
      '[EventAlarmScheduler] Scheduling ${event.id} at $anchorTime with offsets=${event.reminderOffsets}',
    );
    await _localNotifications.scheduleEventAlarms(
      eventId: event.id,
      eventTitle: event.title,
      anchorTime: anchorTime,
      alarmOffsets: event.reminderOffsets,
    );
    if (signature != null) {
      _lastScheduledSignature[event.id] = signature;
      _lastScheduledOffsets[event.id] = event.reminderOffsets;
    }
  }

  String _signatureFor({
    required DateTime anchorTime,
    required List<int> offsets,
    required String title,
  }) => '${anchorTime.toIso8601String()}|${offsets.join(',')}|$title';
}
