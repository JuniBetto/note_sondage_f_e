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

## First public HTTPS certificate

After `.env.web` points to the real public domain:

```bash
cd /Users/arthurbetto/Documents/work/projectArthur/note_sondage/note_sondage_f_e
podman-compose -f podman-compose.web-public.yml up -d web-nginx
podman-compose -f podman-compose.web-public.yml run --rm --service-ports certbot certonly --webroot -w /var/www/certbot -d "$PUBLIC_WEB_DOMAIN" --email your@email.com --agree-tos --no-eff-email
podman-compose -f podman-compose.web-public.yml up -d
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
