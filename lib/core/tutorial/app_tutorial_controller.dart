import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class AppTutorialController {
  AppTutorialController._();

  static const String _storagePrefix = 'app_tutorial_seen';
  static final Set<String> _startedThisSession = <String>{};

  static Future<void> showIfNeeded({
    required BuildContext context,
    required String tutorialId,
    required List<GlobalKey> keys,
    String? userId,
  }) async {
    final normalizedUserId = _normalizeUserId(userId);
    final sessionKey = '$normalizedUserId::$tutorialId';
    if (_startedThisSession.contains(sessionKey)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storageKey = '$_storagePrefix::$sessionKey';
    final alreadySeen = prefs.getBool(storageKey) ?? false;
    if (alreadySeen) {
      _startedThisSession.add(sessionKey);
      return;
    }

    if (!context.mounted) {
      return;
    }

    final attachedKeys = keys
        .where((key) => key.currentContext != null)
        .toList(growable: false);
    if (attachedKeys.isEmpty) {
      return;
    }

    _startedThisSession.add(sessionKey);

    try {
      ShowcaseView. get().startShowCase(attachedKeys);
      await prefs.setBool(storageKey, true);
    } catch (error, stack) {
      _startedThisSession.remove(sessionKey);
      debugPrint('[Tutorial] Unable to start "$tutorialId": $error\n$stack');
    }
  }

  static Future<void> resetForUser(String? userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    final prefix = '$_storagePrefix::$normalizedUserId::';
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs
        .getKeys()
        .where((entry) => entry.startsWith(prefix))
        .toList(growable: false);
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    _startedThisSession.removeWhere(
      (entry) => entry.startsWith('$normalizedUserId::'),
    );
  }

  static String _normalizeUserId(String? userId) {
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'anonymous';
    }
    return normalized;
  }
}
