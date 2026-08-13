# Note Sondage Frontend

Frontend Flutter dell'ecosistema `Note Sondage`.

## Architettura web aggiornata

Per il canale pubblico ora la parte browser e' separata in due servizi:

- landing SEO Next.js su `teammanagement.it`
- web app Flutter su `app.teammanagement.it`

La separazione evita il conflitto tra home marketing e home autenticata, e rende
piu' semplice indicizzazione, social preview e funnel verso store/login.

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
```

Poi:

- per Web/Desktop puoi usare `flutter run`
- per Android/iOS usa i comandi documentati in [MOBILE_BUILD_MODES.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/MOBILE_BUILD_MODES.md), passando sempre `--dart-define=API_BASE_URL=...`

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
- [note_sondage_vitrine/README.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_vitrine/README.md)

Per il comportamento funzionale dell'app:

- [flutter-app-flusso-feature.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/flutter-app-flusso-feature.md)
- [APP_TUTORIAL_SHOWCASE_FLOW.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/APP_TUTORIAL_SHOWCASE_FLOW.md)
- [TEAMMANAGEMENT_WORKFLOW_ROADMAP.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/TEAMMANAGEMENT_WORKFLOW_ROADMAP.md)
