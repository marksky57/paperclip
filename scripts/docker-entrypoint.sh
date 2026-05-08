#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "[entrypoint] Updating node UID to $PUID"
    usermod -o -u "$PUID" node
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "[entrypoint] Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
fi

# Always normalize /paperclip ownership/permissions before launching the app.
# Railway-mounted volumes default to root-owned, so without this the node user
# (UID 1000) cannot create instance dirs/logs and the app crashes on first boot.
# Idempotent on subsequent restarts (no-op if already correct).
mkdir -p /paperclip
chown -R node:node /paperclip
chmod -R 775 /paperclip

exec gosu node "$@"
