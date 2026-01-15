#!/bin/sh
set -e
echo "Entrypoint starting..."

ASSETS_DIR="${ASSETS_DIR:-$(dirname "$ASSETS_PATH")}"
HYTALE_DOWNLOADER_PATH="${HYTALE_DOWNLOADER_PATH:-/opt/hytale/hytale-downloader}"
ASSETS_VERSION_FILE="${ASSETS_VERSION_FILE:-$ASSETS_DIR/assets.version}"
SERVER_DIR="${SERVER_DIR:-$ASSETS_DIR/server}"
SERVER_JAR="${SERVER_JAR:-$SERVER_DIR/HytaleServer.jar}"
SERVER_AOT="${SERVER_AOT:-$SERVER_DIR/HytaleServer.aot}"
FALLBACK_SERVER_JAR="/opt/hytale/HytaleServer.jar"
FALLBACK_SERVER_AOT="/opt/hytale/HytaleServer.aot"
export ASSETS_DIR ASSETS_PATH

ASSETS_AUTO_UPDATE="${ASSETS_AUTO_UPDATE:-$AUTO_UPDATE}"
ASSETS_AUTO_UPDATE="$(printf "%s" "$ASSETS_AUTO_UPDATE" | tr '[:upper:]' '[:lower:]')"
echo "ASSETS_AUTO_UPDATE=${ASSETS_AUTO_UPDATE}"
echo "ASSETS_PATH=${ASSETS_PATH}"
echo "ASSETS_DIR=${ASSETS_DIR}"

PATCHLINE_ARGS=""
if [ -n "$ASSETS_PATCHLINE" ]; then
  PATCHLINE_ARGS="-patchline $ASSETS_PATCHLINE"
fi

if [ "$ASSETS_AUTO_UPDATE" = "true" ]; then
  if [ ! -x "$HYTALE_DOWNLOADER_PATH" ]; then
    echo "ERROR: hytale-downloader not found or not executable at $HYTALE_DOWNLOADER_PATH"
    echo "Provide it via bind-mount or build it into the image."
    exit 1
  fi

  mkdir -p "$ASSETS_DIR" "$SERVER_DIR"
  echo "Checking latest game version..."
  tmp_log="/tmp/hytale-downloader.version.log"
  : > "$tmp_log"
  "$HYTALE_DOWNLOADER_PATH" -print-version $PATCHLINE_ARGS 2>&1 | tee -a "$tmp_log"
  latest_version="$(tail -n 1 "$tmp_log" | tr -d '\r\n')"
  if [ -z "$latest_version" ]; then
    echo "ERROR: Failed to detect latest asset version."
    echo "If this is the first run, authenticate via the device login shown above."
    exit 1
  fi

  current_version=""
  if [ -f "$ASSETS_VERSION_FILE" ]; then
    current_version="$(tr -d '\r\n' < "$ASSETS_VERSION_FILE")"
  fi

  if [ ! -f "$ASSETS_PATH" ] || [ "$latest_version" != "$current_version" ]; then
    if ! command -v unzip >/dev/null 2>&1; then
      echo "ERROR: unzip is required to extract Assets.zip and server files."
      exit 1
    fi

    tmp_zip="/tmp/hytale-game.zip"
    rm -f "$tmp_zip"

    echo "Downloading game package version $latest_version..."
    "$HYTALE_DOWNLOADER_PATH" -download-path "$tmp_zip" $PATCHLINE_ARGS
    if [ ! -f "$tmp_zip" ]; then
      echo "ERROR: Game package missing after download."
      exit 1
    fi

    echo "Extracting Assets.zip..."
    unzip -o -j "$tmp_zip" "Assets.zip" -d "$ASSETS_DIR"
    if [ ! -f "$ASSETS_PATH" ]; then
      echo "ERROR: Assets.zip missing after extraction."
      exit 1
    fi

    echo "Extracting server binaries..."
    unzip -o -j "$tmp_zip" "Server/HytaleServer.jar" -d "$SERVER_DIR"
    unzip -o -j "$tmp_zip" "Server/HytaleServer.aot" -d "$SERVER_DIR"

    rm -f "$tmp_zip"
    printf "%s\n" "$latest_version" > "$ASSETS_VERSION_FILE"
  else
    echo "Assets already up to date ($current_version)."
  fi
else
  if [ ! -f "$ASSETS_PATH" ]; then
    echo "ERROR: Assets.zip not found at $ASSETS_PATH"
    echo "Set ASSETS_AUTO_UPDATE=true to download assets automatically, or mount Assets.zip."
    exit 1
  fi
fi

if [ ! -f "$SERVER_JAR" ]; then
  SERVER_JAR="$FALLBACK_SERVER_JAR"
  SERVER_AOT="$FALLBACK_SERVER_AOT"
fi

if [ ! -f "$SERVER_JAR" ]; then
  echo "ERROR: HytaleServer.jar not found."
  exit 1
fi

AOT_ARG=""
if [ -f "$SERVER_AOT" ]; then
  AOT_ARG="-XX:AOTCache=$SERVER_AOT"
fi

exec java $JAVA_OPTS \
  $AOT_ARG \
  -jar "$SERVER_JAR" \
  --assets "$ASSETS_PATH" \
  $HYTALE_OPTS
