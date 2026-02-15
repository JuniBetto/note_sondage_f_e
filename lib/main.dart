import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/core/database/hive_initializer.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/error/error_logger.dart';
import 'package:note_sondage/core/error/error_page.dart';
import 'package:note_sondage/ui/main_app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Close Hive boxes when the app is terminated
      HiveInitializer.closeBoxes();
    }
  }
}

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      // 1. Inizializza Flutter binding DENTRO la zona
      WidgetsFlutterBinding.ensureInitialized();
      
      // 2. Setup dependency injection
      setup();
      
      // 3. Inizializza Hive
      await HiveInitializer.initialize();
      
      // 4. Aggiungi observer per lifecycle
      WidgetsBinding.instance.addObserver(AppLifecycleObserver());

      // 5. Inizializza il logger (Sentry)
      await ErrorLogger.init(
        dsn: 'YOUR_DSN_HERE',
        // Attiva Sentry solo in modalità release
        enabled: !kDebugMode,
      );

      // 6. Gestore per errori specifici di Flutter (es. build, layout)
      FlutterError.onError = (FlutterErrorDetails details) {
        // Inoltra l'errore al nostro logger
        ErrorLogger.log(details.exception, details.stack);
      };

      // 7. Costruisce un widget personalizzato in caso di errore
      //    durante la build di un widget.
      ErrorWidget.builder = (FlutterErrorDetails details) {
        // In modalità debug, mostra l'errore standard (schermo rosso)
        if (kDebugMode) {
          return ErrorWidget(details.exception);
        }
        // In produzione, mostra un widget amichevole
        return const Center(
          child: Text(
            "Errore nel widget. 😢",
            style: TextStyle(color: Colors.grey),
          ),
        );
      };

      runApp(MainApp());
    },
    // 8. Questa è la callback di runZonedGuarded.
    // Cattura TUTTI gli errori non gestiti dall'app.
    (error, stack) {
      ErrorLogger.log(error, stack);

      // 9. Naviga alla pagina di errore fatale per l'utente
      // Usiamo la chiave globale per accedere al Navigator
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ErrorPage(error: error.toString()),
        ),
        (route) => false,
      );
    },
  );
}
