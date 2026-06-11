# Fastlane Mobile Delivery

Questo progetto ora usa `fastlane` per pubblicare:

- iOS su `TestFlight`
- Android su `Google Play Internal Testing`

## Percorso consigliato

Per questo progetto il percorso più prudente è:

- `push` / `pull_request`: analisi, test e build
- `workflow_dispatch`: publish mobile

Così eviti di inviare una build agli store a ogni push su `main`.

## File principali

- [Gemfile](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/Gemfile)
- [fastlane/Appfile](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/fastlane/Appfile)
- [fastlane/Fastfile](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/fastlane/Fastfile)
- [.github/workflows/flutter_pipeline.yaml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/.github/workflows/flutter_pipeline.yaml)

## Secrets GitHub richiesti

### Condivisi

- `API_BASE_URL`
- `EMAIL_CONFIRMATION_URL`
- `SENTRY_DSN`

### Android / Google Play

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`

### iOS / TestFlight

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`
- `IOS_CERTIFICATE_P12_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_KEYCHAIN_PASSWORD`

## Prerequisiti iOS da abilitare

Per questa app, prima del publish iOS, devi distinguere bene tra:

- capability da abilitare nel `Portale Apple`
- capability da aggiungere in `Xcode`

### Portale Apple

In `Certificates, Identifiers & Profiles > Identifiers > App ID` abilita:

- `Push Notifications`

Questa e la capability necessaria lato portale perche l'app usa notifiche push via Firebase / APNs.

### Xcode

In `ios/Runner.xcworkspace`, apri:

- `Runner`
- `Signing & Capabilities`

e aggiungi:

- `Background Modes`

Dentro `Background Modes` abilita:

- `Remote notifications`
- `Background fetch`

Nota importante:

- `Background Modes` di solito non compare come capability da attivare nella schermata `Edit your App ID Configuration` del Portale Apple
- quindi e normale non trovarla li
- per questa app va gestita in `Xcode`, non nel portale

### Sign in with Apple

Per ora non e obbligatoria per questa pipeline.

Abilitala solo se vuoi davvero offrire login Apple nell'app.

### Verifica rapida nel progetto

Nel progetto iOS risultano gia presenti:

- [ios/Runner/Runner.entitlements](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/ios/Runner/Runner.entitlements)
  contiene `aps-environment`
- [ios/Runner/Info.plist](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/ios/Runner/Info.plist)
  contiene `UIBackgroundModes` con:
  - `fetch`
  - `remote-notification`

Quindi il setup coerente per iOS e:

- Portale Apple: `Push Notifications`
- Xcode: `Background Modes`
- Xcode > Background Modes:
  - `Remote notifications`
  - `Background fetch`

### Nota su TestFlight / release

In [ios/Runner/Runner.entitlements](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/ios/Runner/Runner.entitlements) il valore attuale e `aps-environment = development`.

Per build `TestFlight` / `App Store`, verifica che:

- il provisioning profile di release sia corretto
- il signing release sia coerente con APNs production

Se il profilo e corretto, Xcode / Apple Signing allineano normalmente il comportamento della build release.

## Cosa fa la pipeline

### Android

Il job `Publish Android Internal Testing`:

1. ricostruisce il keystore da GitHub Secrets
2. genera `android/key.properties`
3. esegue `bundle exec fastlane android internal`
4. carica l`AAB` su `Google Play Internal Testing`

### iOS

Il job `Publish iOS TestFlight`:

1. ricostruisce certificato `.p12`
2. installa il provisioning profile
3. esegue `bundle exec fastlane ios testflight`
4. carica l`IPA` su `TestFlight`

## Come lanciare il publish

Apri GitHub Actions e avvia manualmente:

- `deploy_android = true` per Google Play Internal Testing
- `deploy_ios = true` per TestFlight

Puoi abilitarli entrambi o solo uno.

## Nota importante sul path del workflow

GitHub Actions esegue workflow solo dalla cartella `.github/workflows` del repository GitHub reale.

Se il repository remoto è `note_sondage_f_e`, allora questo path va bene.
Se invece il repository remoto è il monorepo padre `note_sondage`, dovrai spostare o copiare il workflow nella cartella root del repo:

- `/note_sondage/.github/workflows/`
