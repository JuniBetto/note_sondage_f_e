# note_sondage

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Runtime configuration

This frontend uses `API_BASE_URL` through `--dart-define`.
If you want registration emails to land on the app confirmation page, also pass
`EMAIL_CONFIRMATION_URL`.

Important:
- web container builds read `.env.web` during the image build
- mobile builds do not read `.env.web`
- Android / iOS release builds must pass the backend target explicitly
- email confirmation links should point to `/confirm-registration`

Examples:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=EMAIL_CONFIRMATION_URL=http://10.0.2.2:8088/confirm-registration
```

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.20:8080 \
  --dart-define=EMAIL_CONFIRMATION_URL=http://192.168.1.20:8088/confirm-registration
```

```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=EMAIL_CONFIRMATION_URL=https://app.example.com/confirm-registration
```

See also:
- [MOBILE_BUILD_MODES.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/MOBILE_BUILD_MODES.md)
- [SHIFT_CREATE_MODAL.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/SHIFT_CREATE_MODAL.md)
