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

Current public production values:

- web:
  - `teammanagement.it`
- API:
  - `api.teammanagement.it`

## 1b. DuckDNS HTTPS

Use:
- [.env.web.duckdns.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/.env.web.duckdns.example)
- [podman-compose.web-duckdns.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/podman-compose.web-duckdns.yml)
- [podman-compose.duckdns-edge.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/podman-compose.duckdns-edge.yml)

When to use:
- no custom domain yet
- real external browser access is needed
- backend is already exposed on a DuckDNS API hostname

Requirements:
- a DuckDNS hostname for the web app
- router port forwarding for 80 and 443
- the hostname resolves to your public IP
- the shared `note-sondage-public` Podman network

Rootless Podman note:
- keep the edge proxy on local `8080/8443`
- map router public `80/443` to those local ports

## 1c. Cloudflare Tunnel

Use:
- [.env.web.cloudflare-tunnel.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/.env.web.cloudflare-tunnel.example)
- [podman-compose.web-duckdns.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/podman-compose.web-duckdns.yml)
- [podman-compose.cloudflared.yml](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/podman-compose.cloudflared.yml)
- [cloudflared/config.yml.example](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/cloudflared/config.yml.example)

When to use:
- the backend is exposed through Cloudflare Tunnel
- you want the web app public without opening home router ports
- your app is behind CGNAT

Requirements:
- a Cloudflare-managed hostname for the web app
- the shared `note-sondage-public` Podman network
- the same `cloudflared` tunnel used by the backend, or another named tunnel

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
