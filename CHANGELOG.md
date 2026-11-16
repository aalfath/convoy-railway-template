# Changelog

## 2026-11-16: Convoy v26.9.5 (first release)

- Convoy `v26.9.5` (`getconvoy/convoy@sha256:f8c886a1a62da8d0edfbf47ec5a367b6e5c75629721637e1baa88cc60dc23a76`), Caddy `2.11.9` as the in-container router.
- One `Convoy` service runs `convoy server` and `convoy agent`; Railway Postgres and Redis hold the data.
- First boot creates the admin from `CONVOY_ADMIN_EMAIL` / `CONVOY_ADMIN_PASSWORD`; no default superuser; public sign-up off; log level `warn`.
