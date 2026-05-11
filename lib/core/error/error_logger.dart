import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Un wrapper statico per il nostro servizio di logging (Sentry)
class ErrorLogger {
  static bool _isEnabled = false;
  static String? _lastDebugMessage;
  static DateTime? _lastDebugMessageAt;
  static int _suppressedDebugDuplicates = 0;

  /// Inizializza Sentry.
  /// Chiamare in main.dart
  static Future<void> init({required String dsn, bool? enabled}) async {
    final sentryEnvironment = RuntimeConfig.sentryEnvironment;
    final normalizedDsn = dsn.trim();

    _isEnabled =
        enabled ??
        (normalizedDsn.isNotEmpty &&
            normalizedDsn != RuntimeConfig.defaultSentryDsn);

    if (!_isEnabled) {
      debugPrint(
        "[ErrorLogger] Logging disabilitato (DSN assente o 'enabled: false').",
      );
      return;
    }

    try {
      await SentryFlutter.init((options) {
        options.dsn = normalizedDsn;
        // Imposta tracesSampleRate a 1.0 per il performance monitoring
        options.environment = sentryEnvironment;
        options.tracesSampleRate = 1.0;
      });
      debugPrint(
        "[ErrorLogger] Sentry inizializzato con successo in ambiente $sentryEnvironment.",
      );
    } catch (e, stack) {
      debugPrint(
        "[ErrorLogger] Errore durante l'inizializzazione di Sentry: $e",
      );
      debugPrint(stack.toString());
      _isEnabled = false;
    }
  }

  /// Registra un errore su Sentry.
  static Future<void> log(Object error, StackTrace? stackTrace) async {
    // In release/profile stampa anche in console locale per facilitare il debug.
    if (!kDebugMode) {
      debugPrint("--- ERRORE CATTURATO ---");
      debugPrint(error.toString());
      debugPrint(stackTrace?.toString() ?? "Stack non disponibile");
      debugPrint("------------------------");
    }

    // Se il logger è disabilitato, non inviare nulla a Sentry.
    if (!_isEnabled) {
      _debugPrint(error.toString());
      return;
    }

    try {
      await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (e) {
      debugPrint("[ErrorLogger] Errore durante l'invio a Sentry: $e");
    }
  }

  static void _debugPrint(String message) {
    final normalizedMessage = message.trim();
    final now = DateTime.now();
    final isDuplicate =
        _lastDebugMessage == normalizedMessage &&
        _lastDebugMessageAt != null &&
        now.difference(_lastDebugMessageAt!) < const Duration(seconds: 8);

    if (isDuplicate) {
      _suppressedDebugDuplicates += 1;
      if (_suppressedDebugDuplicates == 1 ||
          _suppressedDebugDuplicates % 5 == 0) {
        debugPrint(
          '----error debug :  $normalizedMessage '
          '(repeated $_suppressedDebugDuplicates times)',
        );
      }
      _lastDebugMessageAt = now;
      return;
    }

    if (_suppressedDebugDuplicates > 0 && _lastDebugMessage != null) {
      debugPrint(
        '----error debug :  ${_lastDebugMessage!} '
        '(suppressed $_suppressedDebugDuplicates duplicate logs)',
      );
    }

    _lastDebugMessage = normalizedMessage;
    _lastDebugMessageAt = now;
    _suppressedDebugDuplicates = 0;
    debugPrint('----error debug :  $normalizedMessage');
  }
}
