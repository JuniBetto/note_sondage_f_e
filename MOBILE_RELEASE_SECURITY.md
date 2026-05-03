# Mobile Release Security

## Important truth

No mobile app can be made impossible to copy or reverse engineer.

What you can do is raise the cost:
- sign release builds correctly
- obfuscate release code
- keep every real permission check on the backend
- never embed backend secrets in the app
- use HTTPS in production

Important:
- `google-services.json`, `GoogleService-Info.plist` and `firebase_options.dart` contain client configuration, not backend secrets
- they should still be restricted correctly in Firebase / Google Cloud console

## What is now ready

- API target is configurable with `--dart-define=API_BASE_URL=...`
- Android release signing can use a real keystore through [android/key.properties.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/android/key.properties.example)
- Android cleartext HTTP can be enabled only for specific LAN test builds through the `usesCleartextTraffic=true` Gradle property

## Android release

1. Create `android/key.properties` from the example:

```bash
cp /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/android/key.properties.example /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/android/key.properties
```

2. Put the real keystore path and passwords in it.

3. Build with obfuscation:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android \
  --dart-define=API_BASE_URL=https://api.example.com
```

For first LAN HTTP tests only:

Temporarily add this line to `android/gradle.properties`:

```text
usesCleartextTraffic=true
```

Then build:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.20 \
  --obfuscate \
  --split-debug-info=build/symbols/android
```

Remove that line again before production builds.

## iOS release

Recommended:
- prefer `LAN HTTPS` or `Public HTTPS`
- do not relax ATS broadly for production
- archive from Xcode with a real Apple signing identity

Build example:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios \
  --dart-define=API_BASE_URL=https://api.example.com
```

## Extra hardening you should plan next

- Firebase App Check or a similar app-attestation layer
- Play Integrity for Android
- App Attest / DeviceCheck for iOS
- backend rate limits and anomaly detection
- certificate pinning only after the public HTTPS topology is stable

## Non-negotiable rule

Never trust the app to enforce authorization.
If someone extracts or patches the mobile binary, the backend must still reject any forbidden action.
