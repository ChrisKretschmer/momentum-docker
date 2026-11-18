# momentum-docker

Runs the [Momentum](https://momentum-client.com) desktop client in a container
and makes it reachable via VNC or in the browser via noVNC (fluxbox + TightVNC).

## Quick start

```sh
cp .env.example .env      # set VNC_PASSWORD
docker compose up -d      # pulls the image, or `docker compose up -d --build`
```

Then either

- open <http://localhost:6080/> in a browser (noVNC), or
- connect a VNC client to `localhost:5901`.

## Configuration

Container environment:

| Variable            | Default          | Description                                                                 |
| ------------------- | ---------------- | --------------------------------------------------------------------------- |
| `VNC_PASSWORD`      | random           | VNC password (also used by noVNC). Only the first 8 characters are used. If unset, a random one is generated on each start and printed to the log. |
| `VNC_PASSWORD_FILE` | –                | Read the password from a file instead (e.g. a Docker secret).              |
| `NOVNC_ENABLED`     | `true`           | Start the noVNC web client.                                                 |
| `RESOLUTION`        | `1920x1080`      | Desktop size.                                                               |
| `TZ`                | `Europe/Berlin`  | Time zone.                                                                  |

Port publishing (`docker-compose.yml` / `.env`):

| Variable     | Default     | Description                                          |
| ------------ | ----------- | ---------------------------------------------------- |
| `VNC_BIND`   | `127.0.0.1` | Host interface for VNC. `0.0.0.0` = all interfaces.  |
| `VNC_PORT`   | `5901`      | Host port for VNC.                                   |
| `NOVNC_BIND` | `127.0.0.1` | Host interface for noVNC. `0.0.0.0` = all interfaces.|
| `NOVNC_PORT` | `6080`      | Host port for noVNC.                                 |

Volumes:

- `/root/.config/Momentum` – app configuration (named volume `momentum`)
- `/root/Momentum` – downloads (`./data`)

## Security

VNC and noVNC traffic is **not encrypted** and VNC authentication is limited to
8 characters. Both ports are therefore bound to localhost by default. To reach
them remotely, prefer one of:

- an SSH tunnel: `ssh -L 6080:localhost:6080 your-server`
- a VPN
- a reverse proxy with TLS (and ideally its own authentication) in front of
  port 6080 — noVNC works over WebSockets, so the proxy must forward
  `Upgrade`/`Connection` headers.
