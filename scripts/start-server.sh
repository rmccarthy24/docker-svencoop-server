#!/bin/bash
set -euo pipefail

PUID="${PUID:-99}"
PGID="${PGID:-100}"

# ---- Phase 1: running as root, fix ownership and drop privileges ----
if [ "$(id -u)" = "0" ]; then
    groupmod -o -g "$PGID" steam
    usermod  -o -u "$PUID" -g "$PGID" steam
    mkdir -p "$STEAMCMD_DIR" "$SERVER_DIR"
    chown "$PUID:$PGID" "$DATA_DIR"
    for d in "$STEAMCMD_DIR" "$SERVER_DIR"; do
        # only recurse when the top-level owner is wrong (avoids slow chown on every start)
        if [ "$(stat -c %u "$d")" != "$PUID" ]; then
            chown -R "$PUID:$PGID" "$d"
        fi
    done
    exec setpriv --reuid="$PUID" --regid="$PGID" --init-groups \
         env HOME="$DATA_DIR" "$0" "$@"
fi

# ---- Phase 2: running as the steam user ----
export HOME="${HOME:-$DATA_DIR}"

if [ ! -x "${STEAMCMD_DIR}/steamcmd.sh" ]; then
    echo "---SteamCMD not found, downloading---"
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar -xz -C "$STEAMCMD_DIR"
fi

if [ -n "${STEAM_USER:-}" ]; then
    LOGIN=(+login "$STEAM_USER" "$STEAM_PASSWORD")
else
    LOGIN=(+login anonymous)
fi

UPDATE=(+force_install_dir "$SERVER_DIR" "${LOGIN[@]}" +app_update "$GAME_ID")
if [ "${VALIDATE:-}" = "true" ]; then
    echo "---Validating installation---"
    UPDATE+=(validate)
fi
UPDATE+=(+quit)

echo "---Updating server---"
# The first SteamCMD run self-updates and often exits non-zero, so retry
for attempt in 1 2 3; do
    "${STEAMCMD_DIR}/steamcmd.sh" "${UPDATE[@]}" && [ -f "${SERVER_DIR}/svends_run" ] && break
    echo "SteamCMD attempt ${attempt} did not finish cleanly, retrying..."
    sleep 3
done

if [ ! -f "${SERVER_DIR}/svends_run" ]; then
    echo "ERROR: svends_run not found after install, giving up." >&2
    exit 1
fi

echo "---Preparing Steam SDK---"
mkdir -p "$HOME/.steam/sdk32"
ln -sf "${STEAMCMD_DIR}/linux32/steamclient.so" "$HOME/.steam/sdk32/steamclient.so"

echo "---Starting server---"
cd "$SERVER_DIR"
# GAME_PARAMS is intentionally unquoted so it word-splits into arguments
exec ./svends_run ${GAME_PARAMS} -console -port "${GAME_PORT}"