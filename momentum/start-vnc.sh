#!/bin/bash
set -euo pipefail

DISPLAY_NUM=1
VNC_DIR="$HOME/.vnc"
RESOLUTION="${RESOLUTION:-1920x1080}"

# --- /etc/hosts -------------------------------------------------------------
# Only add the entry once; the file survives container restarts.
HOSTNAME=$(hostname)
if ! grep -qE "[[:space:]]${HOSTNAME}\$" /etc/hosts; then
    echo 'Updating /etc/hosts file...'
    printf '127.0.1.1\t%s\n' "$HOSTNAME" >> /etc/hosts || true
fi

# --- VNC password -----------------------------------------------------------
# Priority: VNC_PASSWORD_FILE (e.g. Docker secret) > VNC_PASSWORD > random.
# Note: classic VNC authentication only uses the first 8 characters.
mkdir -p "$VNC_DIR"
if [ -n "${VNC_PASSWORD_FILE:-}" ]; then
    VNC_PASSWORD=$(head -n1 "$VNC_PASSWORD_FILE")
fi
if [ -z "${VNC_PASSWORD:-}" ]; then
    VNC_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
    echo "No VNC_PASSWORD set, generated a random one for this run: $VNC_PASSWORD"
fi
if [ "${#VNC_PASSWORD}" -gt 8 ]; then
    echo "Warning: VNC only uses the first 8 characters of the password."
fi
printf '%s\n' "$VNC_PASSWORD" | vncpasswd -f > "$VNC_DIR/passwd"
chmod 600 "$VNC_DIR/passwd"
unset VNC_PASSWORD

# --- Stale lock cleanup -----------------------------------------------------
echo "Cleaning up stale VNC lock/pid files for display :$DISPLAY_NUM..."
# Try a graceful kill first (ignores errors if nothing is running)
vncserver -kill ":$DISPLAY_NUM" >/dev/null 2>&1 || true

# Remove leftover locks/sockets/pids that survive a container stop/restart
# and would otherwise force the server onto an incrementing display number.
rm -f "/tmp/.X${DISPLAY_NUM}-lock"
rm -f "/tmp/.X11-unix/X${DISPLAY_NUM}"
rm -f "$VNC_DIR"/*:"${DISPLAY_NUM}".pid
rm -f "$VNC_DIR"/*:"${DISPLAY_NUM}".log

# --- Start ------------------------------------------------------------------
echo "Starting VNC server at $RESOLUTION on display :$DISPLAY_NUM..."
vncserver ":$DISPLAY_NUM" -geometry "$RESOLUTION"

NOVNC_PID=""
if [ "${NOVNC_ENABLED:-true}" = "true" ]; then
    NOVNC_PORT="${NOVNC_PORT:-6080}"
    echo "Starting noVNC on port $NOVNC_PORT..."
    websockify --web /usr/share/novnc "$NOVNC_PORT" "localhost:$((5900 + DISPLAY_NUM))" &
    NOVNC_PID=$!
fi

export DISPLAY=":$DISPLAY_NUM"
momentum-prod --no-sandbox &
APP_PID=$!

# Graceful shutdown: on container stop (SIGTERM/SIGINT) kill the VNC server
# so its lock/pid files are removed cleanly instead of being left behind.
shutdown() {
    echo "Received shutdown signal, stopping Momentum and VNC server on display :$DISPLAY_NUM..."
    kill "$APP_PID" $NOVNC_PID 2>/dev/null || true
    vncserver -kill ":$DISPLAY_NUM" >/dev/null 2>&1 || true
    rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}"
    exit 0
}
trap shutdown SIGTERM SIGINT

# Wait on Momentum itself: if it crashes the container exits and the
# restart policy brings it back, instead of leaving an empty VNC desktop.
set +e
wait "$APP_PID"
STATUS=$?
echo "Momentum exited with status $STATUS"
[ -n "$NOVNC_PID" ] && kill "$NOVNC_PID" 2>/dev/null
vncserver -kill ":$DISPLAY_NUM" >/dev/null 2>&1 || true
exit "$STATUS"
