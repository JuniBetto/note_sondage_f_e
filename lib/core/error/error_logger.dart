import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Un wrapper statico per il nostro servizio di logging (Sentry)
class ErrorLogger {
  static bool _isEnabled = false;

  /// Inizializza Sentry.
  /// Chiamare in main.dart
  static Future<void> init({required String dsn, bool enabled = true}) async {
    _isEnabled = enabled;
    if (!_isEnabled) {
      debugPrint(
        "[ErrorLogger] Logging disabilitato (kDebugMode o 'enabled: false').",
      );
      return;
    }

    try {
      await SentryFlutter.init((options) {
        options.dsn = dsn;
        // Imposta tracesSampleRate a 1.0 per il performance monitoring
        options.tracesSampleRate = 1.0;
      });
      debugPrint("[ErrorLogger] Sentry inizializzato con successo.");
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
    // In modalità debug, stampa solo in console.
    if (!kDebugMode) {
      debugPrint("--- ERRORE CATTURATO ---");
      debugPrint(error.toString());
      debugPrint(stackTrace?.toString() ?? "Stack non disponibile");
      debugPrint("------------------------");
    }

    // Se il logger è disabilitato (es. in debug), non inviare nulla.
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
