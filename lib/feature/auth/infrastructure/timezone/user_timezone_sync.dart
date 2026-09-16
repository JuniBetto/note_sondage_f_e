import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Reports the active device's IANA zone, independently of push permissions.
/// Opening/resuming the app reasserts this device as the account's reference.
class UserTimezoneSync {
  UserTimezoneSync({
    required String? Function() currentUserId,
    required Future<void> Function(String userId, String timezone) saveTimezone,
    Future<String> Function()? readTimezone,
  }) : _currentUserId = currentUserId,
       _saveTimezone = saveTimezone,
       _readTimezone = readTimezone ?? FlutterTimezone.getLocalTimezone;

  final String? Function() _currentUserId;
  final Future<void> Function(String, String) _saveTimezone;
  final Future<String> Function() _readTimezone;
  Timer? _timer;
  int _generation = 0;
  int? _inFlightGeneration;
  bool _active = false;
  bool _needsActivationSync = true;
  String? _syncedUserId;
  String? _syncedTimezone;

  void resume() {
    _active = true;
    _generation++;
    _needsActivationSync = true;
    _timer?.cancel();
    // Detect a system timezone change while the app stays open, and retry
    // failed synchronization without making authentication depend on it.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(sync());
    });
    unawaited(sync());
  }

  void pause() {
    _active = false;
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> sync() async {
    final generation = _generation;
    final userId = _currentUserId();
    if (!_active ||
        userId == null ||
        userId.isEmpty ||
        _inFlightGeneration == generation) {
      return;
    }
    _inFlightGeneration = generation;
    try {
      final timezone = (await _readTimezone()).trim();
      if (!_active ||
          generation != _generation ||
          userId != _currentUserId() ||
          timezone.isEmpty) {
        return;
      }
      if (!_needsActivationSync &&
          userId == _syncedUserId &&
          timezone == _syncedTimezone) {
        return;
      }
      await _saveTimezone(userId, timezone);
      if (_active && generation == _generation && userId == _currentUserId()) {
        _syncedUserId = userId;
        _syncedTimezone = timezone;
        _needsActivationSync = false;
      }
    } catch (error) {
      // Keep the server's last known zone. Never replace a failed detection
      // with an invented UTC offset or block login/the rest of the app.
      debugPrint('[UserTimezoneSync] Synchronization deferred: $error');
    } finally {
      if (_inFlightGeneration == generation) {
        _inFlightGeneration = null;
      }
    }
  }

  void dispose() => pause();
}
