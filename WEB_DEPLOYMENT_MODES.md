# Web Deployment Modes

## 1. Public HTTPS

Use:
- [.env.web.public.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/.env.web.public.example)
- [podman-compose.web-public.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/podman-compose.web-public.yml)
- [nginx/templates/default.conf.template](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/nginx/templates/default.conf.template)

When to use:
- real internet-facing frontend
- real domain
- Let's Encrypt

## 2. LAN HTTP

Use:
- [.env.web.lan-http.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/.env.web.lan-http.example)
- [podman-compose.web-lan-http.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/podman-compose.web-lan-http.yml)
- [nginx/templates-lan-http/default.conf.template](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/nginx/templates-lan-http/default.conf.template)

When to use:
- first browser tests on your internal network
- IP-based access like `http://192.168.1.20:8088`
- no domain yet

Limits:
- mobile apps should prefer `LAN HTTPS` or `Public HTTPS`
- web auth / push / browser trust are weaker than HTTPS

## 3. LAN HTTPS

Use:
- [.env.web.lan-https.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/.env.web.lan-https.example)
- [podman-compose.web-lan-https.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/podman-compose.web-lan-https.yml)
- [nginx/templates-lan-https/default.conf.template](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/nginx/templates-lan-https/default.conf.template)

When to use:
- internal network
- realistic mobile/browser tests before buying or exposing a public domain

Default test ports:
- `http://<host>:8088`
- `https://<host>:8443`

Requirements:
- trusted certs in `note_sondage_f_e/nginx/certs/`
  - `fullchain.pem`
  - `privkey.pem`

## Important runtime note

The app now supports `API_BASE_URL` through `--dart-define`.

That means:
- web can target `https://api.example.com`
- Android/iOS builds can target `https://api.example.com`
- Android LAN HTTP tests can target `http://192.168.x.x`

Without changing code again.

Additional web-only runtime values used during image build:

- `APPLE_STORE_URL`
- `ANDROID_STORE_URL`

These are used by the mobile-web gate shown when the browser width is below `576px`.

Important distinction:
- `.env.web` is read directly during the web image build
- mobile APK / IPA do not read `.env.web`
- Android and iOS builds must pass `API_BASE_URL` explicitly with `--dart-define`

Examples:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.20:8080
```

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
```
