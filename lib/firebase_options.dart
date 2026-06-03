// ╔══════════════════════════════════════════════════════════════════╗
// ║  PLACEHOLDER — esegui il comando seguente per generare          ║
// ║  il file definitivo con le chiavi del tuo progetto Firebase:    ║
// ║                                                                  ║
// ║  dart pub global activate flutterfire_cli                       ║
// ║  flutterfire configure                                           ║
// ║                                                                  ║
// ║  Il CLI creerà firebase_options.dart con la classe              ║
// ║  DefaultFirebaseOptions contenente le configurazioni per        ║
// ║  Android, iOS e Web.                                            ║
// ╚══════════════════════════════════════════════════════════════════╝

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Placeholder — verrà sostituito da `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyA8-Dy4yEF83j-6XFAAAZVG_8VfRZG3a2Q",
      authDomain: "notesondage.firebaseapp.com",
      projectId: "notesondage",
      storageBucket: "notesondage.firebasestorage.app",
      messagingSenderId: "907402131431",
      appId: "1:907402131431:web:7da10e38061b426fed6f42"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'LA_TUA_API_KEY_ANDROID',
    appId: 'LA_TUA_APP_ID_ANDROID',
    messagingSenderId: 'IL_TUO_SENDER_ID',
    projectId: 'note-sondage',
    storageBucket: 'note-sondage.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'LA_TUA_API_KEY_IOS',
    appId: 'LA_TUA_APP_ID_IOS',
    messagingSenderId: 'IL_TUO_SENDER_ID',
    projectId: 'note-sondage',
    storageBucket: 'note-sondage.appspot.com',
    iosBundleId: 'com.example.noteSondage',
  );
}
