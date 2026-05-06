# Mobile Build Modes

This file collects the practical build commands for Android and iOS, depending
on where the backend is running.

Important:
- mobile builds do not read `.env.web`
- mobile runtime target must be passed with `--dart-define=API_BASE_URL=...`
- custom registration confirmation emails should pass `--dart-define=EMAIL_CONFIRMATION_URL=...`
- `127.0.0.1` on a phone points to the phone itself
- Android emulator must use `10.0.2.2`

## 1. Local debug on Android emulator

Use this when:
- backend runs on your local machine
- app runs in the Android emulator

Backend target:
- `http://10.0.2.2:8080`

Run:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=EMAIL_CONFIRMATION_URL=http://10.0.2.2:8088/confirm-registration
```

## 2. Local debug on iOS simulator / desktop

Use this when:
- backend runs on your local machine
- app runs on iOS simulator, macOS, or local desktop

Backend target:
- `http://127.0.0.1:8080`

Run:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=EMAIL_CONFIRMATION_URL=http://127.0.0.1:8088/confirm-registration
```

## 3. Local debug on physical phone over LAN

Use this when:
- backend runs on your computer or server in the same LAN
- app runs on a real Android or iPhone device

Backend target:
- `http://<LAN-IP>:8080`

Example:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.20:8080 \
  --dart-define=EMAIL_CONFIRMATION_URL=http://192.168.1.20:8088/confirm-registration
```

Notes:
- Android may need cleartext HTTP enabled for LAN HTTP tests
- for more realistic tests, prefer LAN HTTPS or Public HTTPS

## 4. Android APK for LAN testing

Use this when:
- you want an installable APK for a real Android device
- backend is reachable on the local network

Example:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.20:8080 \
  --dart-define=EMAIL_CONFIRMATION_URL=http://192.168.1.20:8088/confirm-registration
```

If you need HTTP on Android release/LAN builds, verify the project is
configured for cleartext traffic only for that test scenario.

## 5. Android APK / AAB for public HTTPS

Use this when:
- backend is exposed through a real HTTPS domain
- you want a production-like Android build

Example APK:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

Example App Bundle:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/android \
  --dart-define=API_BASE_URL=https://api.example.com
```

## 6. iOS IPA for public HTTPS

Use this when:
- backend is exposed through a real HTTPS domain
- you want a production-like iOS build

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios \
  --dart-define=API_BASE_URL=https://api.example.com
```

## 7. Optional define file

If your Flutter version supports `--dart-define-from-file`, you can store
mobile targets in a dedicated file instead of repeating them on the command line.

Example file `.env.android.lan`:

```env
API_BASE_URL=http://192.168.1.20:8080
SENTRY_DSN=
GOOGLE_SIGN_IN_SERVER_CLIENT_ID=your-client-id
```

Then:

```bash
flutter build apk --release --dart-define-from-file=.env.android.lan
```

If `--dart-define-from-file` is not supported in your environment, use plain
`--dart-define=...`.

## 8. Quick reference

- Android emulator -> `http://10.0.2.2:8080`
- iOS simulator / desktop -> `http://127.0.0.1:8080`
- real device on LAN -> `http://<server-ip>:8080`
- production release -> `https://api.example.com`
