# Use an official Ubuntu base image
FROM ubuntu:24.04

# Avoid warnings by switching to noninteractive for the build process
ENV DEBIAN_FRONTEND=noninteractive

ENV USER=root

RUN apt-get update && apt-get install -y --no-install-recommends wget \
    && apt-get clean && rm -rf momentum.deb /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install XFCE, VNC server, dbus-x11, and xfonts-base
RUN wget --no-check-certificate https://momentum-client.com/apps/momentum.deb \
    && apt-get update && apt-get install -y --no-install-recommends \
    libgbm1 libasound2t64 \
    ./momentum.deb \
    fluxbox xterm \
    tightvncserver \
    dbus-x11 \
    xfonts-base \
    && apt-get clean && rm -rf momentum.deb /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup VNC server
RUN mkdir /root/.vnc \
    && echo "23xVThFQ7N!sHZ" | vncpasswd -f > /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Create an .Xauthority file
RUN touch /root/.Xauthority

# Set display resolution (change as needed)
ENV RESOLUTION=1920x1080

# Expose VNC port
EXPOSE 5901

# Set the working directory in the container
WORKDIR /app

# Copy a script to start the VNC server
COPY start-vnc.sh start-vnc.sh
RUN chmod +x start-vnc.sh

### config files
VOLUME /root/.config/Momentum
### downloads
VOLUME /root/Momentum



# List the contents of the /app directory

CMD ./start-vnc.sh
