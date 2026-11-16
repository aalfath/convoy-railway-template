# Convoy on Railway

Railway template for [Convoy](https://github.com/frain-dev/convoy), the webhooks gateway for sending, receiving and retrying webhooks.

**Version:** Convoy `v26.9.5` (`getconvoy/convoy:v26.9.5@sha256:f8c886a1a62da8d0edfbf47ec5a367b6e5c75629721637e1baa88cc60dc23a76`).

## What it deploys

| Service | Source | Notes |
|---|---|---|
| **Convoy** | this repo (`Dockerfile`) | `convoy server` (dashboard, management API) and `convoy agent` (webhook delivery worker, `/ingest`) in one container, behind a small Caddy router on Railway's `PORT`. Public domain, health check `/healthz` |
| **Postgres** | Railway Postgres | all Convoy data, on a volume |
| **Redis** | Railway Redis | queues and cache, on a volume |

On every start, `start.sh` runs `convoy migrate up`. On the **first** start (empty user table) it creates your admin account from `CONVOY_ADMIN_EMAIL` and `CONVOY_ADMIN_PASSWORD` before Convoy starts. Convoy never creates its built-in `superuser@default.com` / `default` account. Public sign-up is off.

## Variables (Convoy service)

| Variable | Default | What it is |
|---|---|---|
| `CONVOY_ADMIN_EMAIL` | `admin@example.com` | Login email of the admin, created on first boot |
| `CONVOY_ADMIN_PASSWORD` | generated | Admin password, used on first boot only. Read it in the service's Variables tab. Change it later in Convoy's profile settings |
| `CONVOY_HOST` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL, used in source (ingest) URLs and portal links |
| `CONVOY_JWT_SECRET`, `CONVOY_JWT_REFRESH_SECRET` | generated | Dashboard session signing keys |
| `CONVOY_DB_*`, `CONVOY_REDIS_*` | references | Point at the Postgres and Redis services over the private network |
| `PORT` | `8080` | Public port (Caddy) |

Optional settings (SMTP, OAuth, log level, retention) use Convoy's own `CONVOY_*` variables, see [`convoy.env.example`](https://github.com/frain-dev/convoy/blob/main/convoy.env.example). Set `CONVOY_LOGGER_LEVEL=info` for verbose logs (default here: `warn`).

## License and limits

Convoy is source-available under the [Elastic License 2.0](https://github.com/frain-dev/convoy/blob/main/LICENSE). Self-hosting for your own use is allowed. Without a license key, Convoy runs as the Community edition: 1 user, 1 organisation and 2 projects. A key from Convoy (`CONVOY_LICENSE_KEY`) lifts those limits. This repo only contains the Railway wrapper (MIT-style, no Convoy code).

## Updates

Railway tells you when this repo's `main` branch changes ("update available" on your project). Each change is listed in [`CHANGELOG.md`](CHANGELOG.md), with breaking changes first. Back up Postgres before applying an update that bumps the Convoy version: migrations run automatically on start.
