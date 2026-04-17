import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:note_sondage/core/database/hive_initializer.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/error/error_logger.dart';
import 'package:note_sondage/core/error/error_page.dart';
import 'package:note_sondage/firebase_options.dart';
import 'package:note_sondage/ui/main_app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      // 1. Inizializza Flutter binding DENTRO la zona
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Inizializza Firebase (necessario per FirebaseAuth)
      //    Su Android il plugin nativo può già aver inizializzato l'app,
      //    quindi ignoriamo l'errore "duplicate-app".
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
        debugPrint('[Firebase] Already initialized, skipping.');
      }

      // 3. Setup dependency injection (sincrono — va prima delle init async)
      setup();

      // 4. Inizializza in parallelo le operazioni indipendenti:
      //    - Google Sign-In (obbligatorio per v7+)
      //    - Hive (database locale)
      //    - Sentry (error logger)
      //    Questo riduce i tempi di avvio perché non si aspettano a vicenda.
      await Future.wait([
        GoogleSignIn.instance.initialize(),
        HiveInitializer.initialize(),
        ErrorLogger.init(dsn: 'YOUR_DSN_HERE', enabled: !kDebugMode),
      ]);

      // 5. Gestore per errori specifici di Flutter (es. build, layout)
      FlutterError.onError = (FlutterErrorDetails details) {
        // ── DEBUG: stampa anche lo stack per trovare la riga esatta ──
        debugPrint("━━━ FlutterError ━━━");
        debugPrint("Exception: ${details.exception}");
        debugPrint("Stack:\n${details.stack}");
        debugPrint("━━━━━━━━━━━━━━━━━━━");
        // Inoltra l'errore al nostro logger
        ErrorLogger.log(details.exception, details.stack);
      };

      // 6. Costruisce un widget personalizzato in caso di errore
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
    // 7. Questa è la callback di runZonedGuarded.
    // Cattura TUTTI gli errori non gestiti dall'app.
    (error, stack) {
      ErrorLogger.log(error, stack);

      // 8. Naviga alla pagina di errore fatale per l'utente
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
