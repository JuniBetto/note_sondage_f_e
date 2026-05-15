import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class AppTutorialController {
  AppTutorialController._();

  static const String _storagePrefix = 'app_tutorial_seen';
  static final Set<String> _startedThisSession = <String>{};
  static final Map<String, List<GlobalKey>> _registeredTargets =
      <String, List<GlobalKey>>{};
  static final Map<String, Future<void> Function()> _registeredReplays =
      <String, Future<void> Function()>{};

  static Future<void> showIfNeeded({
    required BuildContext context,
    required String tutorialId,
    required List<GlobalKey> keys,
    String? userId,
  }) async {
    registerTargets(tutorialId: tutorialId, keys: keys);
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

    final attachedKeys = _attachedKeys(keys);
    if (attachedKeys.isEmpty) {
      return;
    }

    _startedThisSession.add(sessionKey);

    try {
      ShowCaseWidget.of(context).startShowCase(attachedKeys);
      await prefs.setBool(storageKey, true);
    } catch (error, stack) {
      _startedThisSession.remove(sessionKey);
      debugPrint('[Tutorial] Unable to start "$tutorialId": $error\n$stack');
    }
  }

  static void registerTargets({
    required String tutorialId,
    required List<GlobalKey> keys,
  }) {
    _registeredTargets[tutorialId] = List<GlobalKey>.from(keys);
  }

  static void registerReplayAction({
    required String tutorialId,
    required Future<void> Function() action,
  }) {
    _registeredReplays[tutorialId] = action;
  }

  static Future<void> replay({
    required BuildContext context,
    required List<GlobalKey> keys,
  }) async {
    if (!context.mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      final attachedKeys = _attachedKeys(keys);
      if (attachedKeys.isEmpty) {
        debugPrint('[Tutorial] Replay skipped: no attached keys found.');
        return;
      }

      try {
        final showcase = ShowCaseWidget.of(context);
        showcase.dismiss();
        showcase.startShowCase(attachedKeys);
      } catch (error, stack) {
        debugPrint('[Tutorial] Unable to replay tutorial: $error\n$stack');
      }
    });
  }

  static Future<void> replayRegistered({
    required BuildContext context,
    required String tutorialId,
  }) async {
    final replayAction = _registeredReplays[tutorialId];
    if (replayAction != null) {
      await replayAction();
      return;
    }

    final keys = _registeredTargets[tutorialId];
    if (keys == null || keys.isEmpty) {
      return;
    }
    await replay(context: context, keys: keys);
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

  static List<GlobalKey> _attachedKeys(List<GlobalKey> keys) {
    return keys.toSet().toList(growable: false);
  }
}
