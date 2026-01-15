# Hytale Dedicated Server (Docker)

Minimal Docker image for running a **Hytale Dedicated Server**.

This image contains only the runtime and server binaries.  
Game assets must be provided externally.

---

## Requirements

- Docker
- Docker Compose (optional)
- A valid Hytale account (required on first startup)

Official documentation:  
https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual

---

## Image Contents

- Java (Eclipse Temurin 25)
- `HytaleServer.jar`
- `HytaleServer.aot`

**Not included:**
- `Assets.zip`
- Server data / worlds

---

## Required Assets

You must provide `Assets.zip`. You can either:

- download it manually and mount it into the container, or
- set `ASSETS_AUTO_UPDATE=true` and provide the `hytale-downloader` binary.

For auto-updates, the downloader is bundled in the image at `/opt/hytale/hytale-downloader`.
If the download URL changes, rebuild with `--build-arg HYTALE_DOWNLOADER_URL=...`.

Example host structure:

For auto-update, mount `/assets` as a writable directory (not read-only).

```
/docker/storage/hytale/
├─ data/
└─ assets/
   └─ Assets.zip
```

---

## Docker Run Example

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v /docker/storage/hytale/data:/data \
  -v /docker/storage/hytale/assets:/assets \
  -e JAVA_OPTS="-Dio.netty.transport.noNative=true" \
  gamedevllama/hytale-server
```

Auto-update example:

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v /docker/storage/hytale/data:/data \
  -v /docker/storage/hytale/assets:/assets \
  -e ASSETS_AUTO_UPDATE="true" \
  -e JAVA_OPTS="-Dio.netty.transport.noNative=true" \
  gamedevllama/hytale-server
```

---

## Docker Compose Example

```yaml
services:
  hytale:
    image: gamedevllama/hytale-server
    container_name: hytale-server
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - "5520:5520/udp"
    volumes:
      - /docker/storage/hytale/data:/data
      - /docker/storage/hytale/assets:/assets
      # Optional: provide the downloader binary for auto-updates
      # - /docker/storage/hytale/downloader/hytale-downloader-linux-amd64:/opt/hytale/hytale-downloader:ro
    environment:
      JAVA_OPTS: "-Dio.netty.transport.noNative=true"
      HYTALE_OPTS: ""
      ASSETS_AUTO_UPDATE: "false"
      # ASSETS_PATCHLINE: "pre-release"
```

---

## First-Time Authentication

On first startup, attach to the container:

```bash
docker attach hytale-server
```

Run:

```
/auth login device
```

Follow the instructions to authenticate the server.

Detach safely using:

```
CTRL + P, CTRL + Q
```

---

## Environment Variables

| Variable | Description |
|--------|-------------|
| `ASSETS_PATH` | Path to `Assets.zip` inside container |
| `ASSETS_DIR` | Directory where assets are stored |
| `ASSETS_AUTO_UPDATE` | Set to `true` to check/download assets on startup |
| `ASSETS_PATCHLINE` | Optional patchline (e.g. `pre-release`) |
| `ASSETS_VERSION_FILE` | File storing the last downloaded asset version |
| `HYTALE_DOWNLOADER_PATH` | Path to `hytale-downloader` binary |
| `JAVA_OPTS` | Additional JVM options |
| `HYTALE_OPTS` | Additional Hytale server arguments |

---

## Data Persistence

All runtime data is stored in `/data`.  
Mount this directory to persist worlds and configs.

---

## Disclaimer

Hytale and all related assets are property of Hypixel Studios.  
This image provides only a containerized runtime environment.

---

## Contact

I occasionally share updates and experiments around game development and server tooling on **X**:

🐦 https://x.com/GamedevLlama

Feel free to reach out if you have questions, ideas, or improvements for this setup.
