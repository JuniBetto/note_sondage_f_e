# Note Sondage Frontend

Frontend Flutter dell'ecosistema `Note Sondage`.

L'app copre le aree principali del prodotto:

- autenticazione
- dashboard home
- team
- clocking
- shift
- sondage
- settings
- notifiche realtime

## Stack principale

- Flutter
- `flutter_bloc`
- `get_it`
- `go_router`
- Hive
- SharedPreferences

## Piattaforme

Il frontend supporta:

- Android
- iOS
- Web

## Avvio rapido

```bash
flutter pub get
flutter run
```

## Configurazione runtime

Il frontend usa `--dart-define` per alcuni valori runtime, in particolare:

- `API_BASE_URL`
- `EMAIL_CONFIRMATION_URL`

Per la build web containerizzata vengono usati anche i valori presenti in `.env.web`.

## Dove trovare i dettagli

Per build, deploy e flussi specifici usa le note dedicate:

- [MOBILE_BUILD_MODES.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/MOBILE_BUILD_MODES.md)
- [MOBILE_RELEASE_SECURITY.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/MOBILE_RELEASE_SECURITY.md)
- [WEB_DEPLOYMENT.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/WEB_DEPLOYMENT.md)
- [WEB_DEPLOYMENT_MODES.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/WEB_DEPLOYMENT_MODES.md)
- [SHIFT_CREATE_MODAL.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/SHIFT_CREATE_MODAL.md)

Per il comportamento funzionale dell'app:

- [flutter-app-flusso-feature.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/flutter-app-flusso-feature.md)
- [APP_TUTORIAL_SHOWCASE_FLOW.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/APP_TUTORIAL_SHOWCASE_FLOW.md)
