FROM ubuntu:24.04

# Avoid warnings by switching to noninteractive for the build process
ENV DEBIAN_FRONTEND=noninteractive

# Override at build time to pin/mirror a specific Momentum release
ARG MOMENTUM_DEB_URL=https://momentum-client.com/apps/momentum.deb

# Install Momentum, a minimal window manager and the VNC server
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && wget -q -O /tmp/momentum.deb "$MOMENTUM_DEB_URL" \
    && apt-get install -y --no-install-recommends \
        libgbm1 libasound2t64 \
        /tmp/momentum.deb \
        fluxbox xterm \
        tightvncserver \
        novnc websockify \
        dbus-x11 \
        xfonts-base \
        tzdata \
    && apt-get purge -y wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV USER=root \
    HOME=/root \
    TZ=Etc/UTC \
    RESOLUTION=1920x1080 \
    NOVNC_ENABLED=true \
    NOVNC_PORT=6080

# The VNC password is set at runtime via VNC_PASSWORD or VNC_PASSWORD_FILE,
# never baked into the image.
# Opening http://host:6080/ connects straight to the desktop.
RUN mkdir -p /root/.vnc && touch /root/.Xauthority \
    && rm -f /usr/share/novnc/index.html \
    && printf '%s\n' '<!DOCTYPE html><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale">' \
        > /usr/share/novnc/index.html

WORKDIR /app
COPY --chmod=755 start-vnc.sh start-vnc.sh

# config files
VOLUME /root/.config/Momentum
# downloads
VOLUME /root/Momentum

# 5901 = VNC, 6080 = noVNC (browser)
EXPOSE 5901 6080

CMD ["./start-vnc.sh"]
