# Web Deployment

For the available modes, see:
- [WEB_DEPLOYMENT_MODES.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/WEB_DEPLOYMENT_MODES.md)

## Build behavior

The web image now builds Flutter inside Podman.

So on the server you do **not** need a local `flutter` installation.
The Flutter build reads `.env.web` directly inside the image build and uses:

- `API_BASE_URL`
- `EMAIL_CONFIRMATION_URL`
- `SENTRY_DSN`
- `APPLE_STORE_URL`
- `ANDROID_STORE_URL`

Before going live, also verify:
- the public web domain is added to Firebase / Google authorized domains
- the client id in [web/index.html](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e/web/index.html) is the one you want to keep for production web sign-in

Current public production values:

- web app:
  - `https://teammanagement.it`
- API:
  - `https://api.teammanagement.it`
- email confirmation:
  - `https://teammanagement.it/confirm-registration`

## Start a mode

1. Copy the example env:

```bash
cp .env.web.public.example .env.web
```

or:

```bash
cp .env.web.lan-http.example .env.web
```

or:

```bash
cp .env.web.lan-https.example .env.web
```

or:

```bash
cp .env.web.duckdns.example .env.web
```

or:

```bash
cp .env.web.cloudflare-tunnel.example .env.web
```

2. Start the matching compose file:

```bash
podman-compose -f podman-compose.web-public.yml up -d --build --no-cache
```

or:

```bash
podman-compose -f podman-compose.web-lan-http.yml up -d --build --no-cache
```

Then open:

```text
http://<server-ip>:8088
```

or:

```bash
podman-compose -f podman-compose.web-lan-https.yml up -d --build --no-cache
```

Then open:

```text
https://<server-ip>:8443
```

or for DuckDNS:

```bash
podman network create note-sondage-public
podman-compose -f podman-compose.web-duckdns.yml up -d --build --no-cache
```

Then open:

```text
https://<your-app-host>.duckdns.org
```

or for Cloudflare Tunnel:

```bash
podman network create note-sondage-public
podman-compose -f podman-compose.web-duckdns.yml up -d --build --no-cache
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage
cp cloudflared/config.yml.example cloudflared/config.yml
cp .env.cloudflare-tunnel.edge.example .env.cloudflare-tunnel.edge
podman-compose --env-file .env.cloudflare-tunnel.edge -f podman-compose.cloudflared.yml up -d
```

Then open:

```text
https://<your-app-host>
```

For rootless Podman:

- local edge HTTP port: `8080`
- local edge HTTPS port: `8443`
- router mapping:
  - WAN `80` -> LAN `<server-ip>:8080`
  - WAN `443` -> LAN `<server-ip>:8443`

## Current recommended public deployment

For the Contabo-style public setup, prefer the root runbook and shared edge stack instead of managing the frontend in isolation:

- root script:
  - `bash scripts/deploy/up-public.sh`
- runbook:
  - [CONTABO_VPS_DEPLOYMENT.md](/Users/arthurbetto/Documents/work/projectArthur/note_sondage/CONTABO_VPS_DEPLOYMENT.md)

This keeps:

- frontend public domain
- API public domain
- edge TLS
- backend routing

aligned in one place.

## First public HTTPS certificate

After `.env.web` points to the real public domain:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
podman-compose -f podman-compose.web-public.yml up -d web-nginx
podman-compose -f podman-compose.web-public.yml run --rm --service-ports certbot certonly --webroot -w /var/www/certbot -d "$PUBLIC_WEB_DOMAIN" --email your@email.com --agree-tos --no-eff-email
podman-compose -f podman-compose.web-public.yml up -d
```

## DuckDNS certificate

After `.env.web` points to your real DuckDNS web hostname:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
podman-compose -f podman-compose.web-duckdns.yml up -d web-nginx
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage
cp .env.duckdns.edge.example .env.duckdns.edge
podman-compose -f podman-compose.duckdns-edge.yml --env-file .env.duckdns.edge up -d edge-nginx
podman-compose -f podman-compose.duckdns-edge.yml --env-file .env.duckdns.edge run --rm --service-ports certbot certonly --webroot -w /var/www/certbot -d "$PUBLIC_WEB_DOMAIN" --email your@email.com --agree-tos --no-eff-email
podman-compose -f podman-compose.duckdns-edge.yml --env-file .env.duckdns.edge up -d edge-nginx certbot
```

## Operational note

This web image is multi-stage:
- stage 1 builds the Flutter web bundle
- stage 2 serves the static output with Nginx

If you change frontend code or `.env.web`, rebuild the image:

```bash
podman-compose -f podman-compose.web-public.yml up -d --build
```

## Mobile viewport gate

The web app now blocks the full web UI on very small mobile browsers:

- if viewport width is `< 576px`
- the user sees a store-download screen instead of the normal web app

So before going live, make sure these values are real:

- `APPLE_STORE_URL`
- `ANDROID_STORE_URL`
