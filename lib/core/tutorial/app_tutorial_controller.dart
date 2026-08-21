import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
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
    if (!_tutorialsEnabled) {
      return;
    }
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

    final normalizedKeys = _normalizedKeys(keys);
    if (normalizedKeys.isEmpty) {
      return;
    }

    _startedThisSession.add(sessionKey);

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) {
        _startedThisSession.remove(sessionKey);
        return;
      }
      final mountedKeys = _mountedShowcaseKeys(normalizedKeys);
      if (mountedKeys.isEmpty) {
        _startedThisSession.remove(sessionKey);
        debugPrint(
          '[Tutorial] Skipped "$tutorialId": no mounted showcase targets found.',
        );
        return;
      }
      ShowcaseView.get().startShowCase(mountedKeys);
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

  static void unregisterTutorial(String tutorialId) {
    _registeredTargets.remove(tutorialId);
    _registeredReplays.remove(tutorialId);
  }

  static Future<void> replay({
    required BuildContext context,
    required List<GlobalKey> keys,
  }) async {
    if (!_tutorialsEnabled) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        return;
      }

      final normalizedKeys = _normalizedKeys(keys);
      if (normalizedKeys.isEmpty) {
        debugPrint('[Tutorial] Replay skipped: no registered keys found.');
        return;
      }

      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) {
        return;
      }

      try {
        final mountedKeys = _mountedShowcaseKeys(normalizedKeys);
        if (mountedKeys.isEmpty) {
          debugPrint(
            '[Tutorial] Replay skipped: no mounted showcase targets found.',
          );
          return;
        }
        final showcase = ShowcaseView.get();
        showcase.startShowCase(mountedKeys);
      } catch (error, stack) {
        debugPrint('[Tutorial] Unable to replay tutorial: $error\n$stack');
      }
    });
  }

  static Future<void> replayRegistered({
    required BuildContext context,
    required String tutorialId,
  }) async {
    if (!_tutorialsEnabled) {
      return;
    }
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

  static bool dismissActiveTutorialIfAny() {
    if (!_tutorialsEnabled) {
      return false;
    }

    try {
      final showcase = ShowcaseView.get();
      if (showcase.isShowcaseRunning) {
        showcase.dismiss();
        return true;
      }
    } catch (_) {
      // Ignore missing showcase registrations on screens without tutorials.
    }

    return false;
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

  static List<GlobalKey> _normalizedKeys(List<GlobalKey> keys) {
    final normalized = <GlobalKey>[];
    final seen = <GlobalKey>{};
    for (final key in keys) {
      if (seen.contains(key)) {
        continue;
      }
      normalized.add(key);
      seen.add(key);
    }
    return normalized;
  }

  static List<GlobalKey> _mountedShowcaseKeys(List<GlobalKey> keys) {
    try {
      final showcase = ShowcaseView.get();
      return keys.where(showcase.isTargetRendered).toList(growable: false);
    } catch (_) {
      return const <GlobalKey>[];
    }
  }

  static bool get _tutorialsEnabled => true;
}
