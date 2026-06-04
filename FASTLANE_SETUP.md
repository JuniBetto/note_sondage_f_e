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
