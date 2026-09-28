# momentum-docker

Runs the [Momentum](https://momentum-client.com) desktop client in a container
and makes it reachable via VNC (fluxbox + TightVNC).

## Quick start

```sh
cp .env.example .env      # set VNC_PASSWORD
docker compose up -d      # pulls the image, or `docker compose up -d --build`
```

Then connect a VNC client to `localhost:5901`.

## Configuration

| Variable            | Default          | Description                                                                 |
| ------------------- | ---------------- | --------------------------------------------------------------------------- |
| `VNC_PASSWORD`      | random           | VNC password. Only the first 8 characters are used. If unset, a random one is generated on each start and printed to the log. |
| `VNC_PASSWORD_FILE` | –                | Read the password from a file instead (e.g. a Docker secret).              |
| `VNC_BIND`          | `127.0.0.1`      | Host interface for port 5901 (compose only).                                |
| `RESOLUTION`        | `1920x1080`      | Desktop size.                                                               |
| `TZ`                | `Europe/Berlin`  | Time zone.                                                                  |

Volumes:

- `/root/.config/Momentum` – app configuration (named volume `momentum`)
- `/root/Momentum` – downloads (`./data`)

## Security

VNC traffic is **not encrypted** and VNC authentication is limited to 8
characters. Keep the port bound to localhost and connect through an SSH tunnel
or VPN, e.g.:

```sh
ssh -L 5901:localhost:5901 your-server
```
