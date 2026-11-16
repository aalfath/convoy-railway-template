# Convoy webhook gateway for Railway: server + agent + a small Caddy router in one service.
# Upstream image pinned by version and digest. Bump both together (see CHANGELOG.md).
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM getconvoy/convoy:v26.9.5@sha256:f8c886a1a62da8d0edfbf47ec5a367b6e5c75629721637e1baa88cc60dc23a76

# psql and htpasswd are only used once, to create the first admin before Convoy starts.
RUN apk add --no-cache postgresql-client apache2-utils

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/convoy/Caddyfile
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
