#!/bin/sh
# Start script for the Convoy Railway template.
# 1. run database migrations
# 2. on the very first boot, create the admin from CONVOY_ADMIN_EMAIL / CONVOY_ADMIN_PASSWORD
#    (so Convoy never creates its built-in superuser@default.com / "default" account)
# 3. run convoy server (control plane), convoy agent (data plane) and Caddy (routes the public port)
set -eu

# Railway's PORT is the public port, served by Caddy. Convoy reads PORT itself, so give it its own.
export PUBLIC_PORT="${PORT:-8080}"
export PORT=5005
export AGENT_PORT=5008

: "${CONVOY_DB_HOST:?CONVOY_DB_HOST is required (Postgres)}"
: "${CONVOY_REDIS_HOST:?CONVOY_REDIS_HOST is required (Redis)}"
: "${CONVOY_ADMIN_EMAIL:?CONVOY_ADMIN_EMAIL is required}"
: "${CONVOY_ADMIN_PASSWORD:?CONVOY_ADMIN_PASSWORD is required}"

export CONVOY_DB_SCHEME="${CONVOY_DB_SCHEME:-postgres}"
export CONVOY_DB_PORT="${CONVOY_DB_PORT:-5432}"
export CONVOY_DB_OPTIONS="${CONVOY_DB_OPTIONS:-sslmode=disable&connect_timeout=30}"
export CONVOY_REDIS_SCHEME="${CONVOY_REDIS_SCHEME:-redis}"
export CONVOY_REDIS_PORT="${CONVOY_REDIS_PORT:-6379}"
export CONVOY_SIGNUP_ENABLED="${CONVOY_SIGNUP_ENABLED:-false}"
export CONVOY_LOGGER_LEVEL="${CONVOY_LOGGER_LEVEL:-warn}"

echo "convoy-railway: running database migrations"
/cmd migrate up

export PGPASSWORD="${CONVOY_DB_PASSWORD:-}"
psql_q() {
	psql -h "$CONVOY_DB_HOST" -p "$CONVOY_DB_PORT" -U "$CONVOY_DB_USERNAME" -d "$CONVOY_DB_DATABASE" \
		-v ON_ERROR_STOP=1 -tAq "$@"
}

users="$(psql_q -c 'SELECT count(*) FROM convoy.users')"
if [ "$users" = "0" ]; then
	echo "convoy-railway: first boot, creating the admin account ${CONVOY_ADMIN_EMAIL}"
	# bootstrap creates the user and its "Default Organisation" with a random password,
	# which it prints. Keep that output out of the logs: the password is replaced below.
	if ! /cmd bootstrap --email "$CONVOY_ADMIN_EMAIL" --first-name Admin --last-name User --format json >/dev/null 2>/tmp/bootstrap.err; then
		cat /tmp/bootstrap.err >&2
		exit 1
	fi
	rm -f /tmp/bootstrap.err
	hash="$(htpasswd -nbBC 12 admin "$CONVOY_ADMIN_PASSWORD" | head -n1 | cut -d: -f2 | sed 's/^\$2y\$/$2a$/')"
	psql_q -v hash="$hash" -v email="$CONVOY_ADMIN_EMAIL" <<'SQL'
UPDATE convoy.users SET password = :'hash', email_verified = true WHERE email = :'email';
SQL
	/cmd utils promote-instance-admin --email "$CONVOY_ADMIN_EMAIL" >/dev/null 2>&1 || true
	echo "convoy-railway: admin created (password = CONVOY_ADMIN_PASSWORD variable)"
fi
unset PGPASSWORD

/cmd agent --port 5008 &
agent_pid=$!
/cmd server --port 5005 &
server_pid=$!
caddy run --config /etc/convoy/Caddyfile --adapter caddyfile &
caddy_pid=$!

stop() {
	kill -TERM "$caddy_pid" "$server_pid" "$agent_pid" 2>/dev/null || true
	wait
	exit 0
}
trap stop TERM INT

# If any of the three exits, stop the rest so Railway restarts the container.
while kill -0 "$agent_pid" 2>/dev/null && kill -0 "$server_pid" 2>/dev/null && kill -0 "$caddy_pid" 2>/dev/null; do
	sleep 2
done
echo "convoy-railway: a process exited, stopping the container" >&2
kill -TERM "$caddy_pid" "$server_pid" "$agent_pid" 2>/dev/null || true
wait || true
exit 1
