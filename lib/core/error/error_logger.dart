import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Un wrapper statico per il nostro servizio di logging (Sentry)
class ErrorLogger {
  static bool _isEnabled = false;
  static String? _lastDebugMessage;
  static DateTime? _lastDebugMessageAt;
  static int _suppressedDebugDuplicates = 0;

  /// Registra un errore Flutter arricchito con contesto widget/layout.
  static Future<void> logFlutterError(FlutterErrorDetails details) async {
    if (_shouldIgnore(details.exception)) {
      return;
    }
    final context = _buildFlutterErrorContext(details);
    await log(details.exception, details.stack, context: context);
  }

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
  static Future<void> log(
    Object error,
    StackTrace? stackTrace, {
    ErrorLogContext? context,
  }) async {
    if (_shouldIgnore(error)) {
      return;
    }
    // In release/profile stampa anche in console locale per facilitare il debug.
    if (!kDebugMode) {
      debugPrint("--- ERRORE CATTURATO ---");
      debugPrint(error.toString());
      if (context?.component != null) {
        debugPrint("Component: ${context!.component}");
      }
      debugPrint(stackTrace?.toString() ?? "Stack non disponibile");
      debugPrint("------------------------");
    }

    // Se il logger è disabilitato, non inviare nulla a Sentry.
    if (!_isEnabled) {
      _debugPrint(error.toString());
      return;
    }

    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          final sentryContexts = <String, Object?>{};
          if (context?.component != null) {
            scope.setTag('component', context!.component!);
            sentryContexts['component'] = context.component;
          }
          if (context?.category != null) {
            scope.setTag('error_category', context!.category!);
          }
          final hint = context?.hint;
          if (hint != null) {
            sentryContexts['hint'] = hint;
          }
          if (context != null && context.extras.isNotEmpty) {
            sentryContexts.addAll(context.extras);
          }
          if (sentryContexts.isNotEmpty) {
            scope.setContexts('error_context', sentryContexts);
          }
        },
      );
    } catch (e) {
      debugPrint("[ErrorLogger] Errore durante l'invio a Sentry: $e");
    }
  }

  static ErrorLogContext _buildFlutterErrorContext(
    FlutterErrorDetails details,
  ) {
    final extras = <String, Object?>{};
    final component = _extractRelevantWidget(details);
    final contextDescription = details.context?.toDescription();
    final library = details.library;

    if (library != null && library.isNotEmpty) {
      extras['flutter_library'] = library;
    }
    if (contextDescription != null && contextDescription.isNotEmpty) {
      extras['flutter_context'] = contextDescription;
    }

    final information = <String>[];
    final collector = details.informationCollector;
    if (collector != null) {
      try {
        for (final node in collector()) {
          final description = node.toDescription();
          if (description.isNotEmpty) {
            information.add(description);
          }
        }
      } catch (_) {
        // Ignoriamo collector difettosi per non rompere il logging.
      }
    }
    if (information.isNotEmpty) {
      extras['flutter_information'] = information.join(' | ');
    }

    return ErrorLogContext(
      component: component,
      category: 'flutter',
      hint: contextDescription ?? library,
      extras: extras,
    );
  }

  static String? _extractRelevantWidget(FlutterErrorDetails details) {
    final collector = details.informationCollector;
    if (collector != null) {
      try {
        for (final node in collector()) {
          final text = node.toDescription();
          final match = RegExp(
            r'(?:The relevant error-causing widget was|The ownership chain for the affected widget is):\s*(.+)',
            caseSensitive: false,
          ).firstMatch(text);
          if (match != null) {
            return match.group(1)?.trim();
          }
          final widgetMatch = RegExp(
            r'^([A-Z][A-Za-z0-9_<>]+)\b',
          ).firstMatch(text.trim());
          if (widgetMatch != null) {
            return widgetMatch.group(1)?.trim();
          }
        }
      } catch (_) {
        // Ignora e prova con il contesto sotto.
      }
    }

    final contextDescription = details.context?.toDescription();
    if (contextDescription != null && contextDescription.isNotEmpty) {
      return contextDescription;
    }

    return null;
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

  static bool _shouldIgnore(Object error) {
    if (!kIsWeb) {
      return false;
    }
    return error.toString().contains(
      'Trying to render a disposed EngineFlutterView',
    );
  }
}

class ErrorLogContext {
  const ErrorLogContext({
    this.component,
    this.category,
    this.hint,
    this.extras = const <String, Object?>{},
  });

  final String? component;
  final String? category;
  final String? hint;
  final Map<String, Object?> extras;
}
