import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Un wrapper statico per il nostro servizio di logging (Sentry)
class ErrorLogger {
  static bool _isEnabled = false;

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
      debugPrint("----error debug :  ${error.toString()}");
      return;
    }

    try {
      await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (e) {
      debugPrint("[ErrorLogger] Errore durante l'invio a Sentry: $e");
    }
  }
}
