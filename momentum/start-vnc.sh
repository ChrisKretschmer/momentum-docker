#!/bin/bash

echo 'Updating /etc/hosts file...'
HOSTNAME=$(hostname)
echo "127.0.1.1\t$HOSTNAME" >> /etc/hosts

DISPLAY_NUM=1

echo "Cleaning up stale VNC lock/pid files for display :$DISPLAY_NUM..."
# Try a graceful kill first (ignores errors if nothing is running)
vncserver -kill :$DISPLAY_NUM >/dev/null 2>&1 || true

# Remove leftover locks/sockets/pids that survive a container stop/restart
# and would otherwise force the server onto an incrementing display number.
rm -f /tmp/.X${DISPLAY_NUM}-lock
rm -f /tmp/.X11-unix/X${DISPLAY_NUM}
rm -f /root/.vnc/*:${DISPLAY_NUM}.pid
rm -f /root/.vnc/*:${DISPLAY_NUM}.log

echo "Starting VNC server at $RESOLUTION on display :$DISPLAY_NUM..."
vncserver :$DISPLAY_NUM -geometry $RESOLUTION &

echo "VNC server started at $RESOLUTION! ^-^"

momentum-prod --no-sandbox &

# Graceful shutdown: on container stop (SIGTERM/SIGINT) kill the VNC server
# so its lock/pid files are removed cleanly instead of being left behind.
shutdown() {
    echo "Received shutdown signal, stopping VNC server on display :$DISPLAY_NUM..."
    vncserver -kill :$DISPLAY_NUM >/dev/null 2>&1 || true
    rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM}
    exit 0
}
trap shutdown SIGTERM SIGINT

echo "Starting tail -f /dev/null..."
# `wait` so the trap fires promptly; tail keeps the container alive.
tail -f /dev/null &
wait $!
