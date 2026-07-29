import 'package:flutter/foundation.dart';

class NotificationInteractionGate {
  NotificationInteractionGate._();

  static const Duration _duplicateWindow = Duration(seconds: 5);
  static final Map<String, DateTime> _recentClaims = <String, DateTime>{};

  static String? tryClaimTap({
    required String notificationId,
    String? actionId,
  }) {
    final normalizedNotificationId = notificationId.trim();
    if (normalizedNotificationId.isEmpty) {
      return '';
    }

    final normalizedActionId = actionId?.trim() ?? '';
    final key = 'tap|$normalizedNotificationId|$normalizedActionId';
    final now = DateTime.now();
    _pruneExpiredClaims(now);

    final claimedAt = _recentClaims[key];
    if (claimedAt != null && now.difference(claimedAt) <= _duplicateWindow) {
      debugPrint(
        '[NotificationInteractionGate] Ignored duplicate tap for '
        '$normalizedNotificationId action="$normalizedActionId".',
      );
      return null;
    }

    _recentClaims[key] = now;
    return key;
  }

  static void release(String claimKey) {
    if (claimKey.isEmpty) {
      return;
    }
    _recentClaims.remove(claimKey);
  }

  static void _pruneExpiredClaims(DateTime now) {
    final expiredKeys = <String>[];
    for (final entry in _recentClaims.entries) {
      if (now.difference(entry.value) > _duplicateWindow * 2) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _recentClaims.remove(key);
    }
  }
}
