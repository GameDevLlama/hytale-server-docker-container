FROM eclipse-temurin:25-ubi10-minimal

WORKDIR /opt/hytale

COPY HytaleServer.jar .
COPY HytaleServer.aot .

ARG HYTALE_DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"
RUN microdnf install -y curl unzip \
    && curl -fsSL -o /tmp/hytale-downloader.zip "$HYTALE_DOWNLOADER_URL" \
    && unzip -j /tmp/hytale-downloader.zip "hytale-downloader-linux-amd64" -d /opt/hytale \
    && mv /opt/hytale/hytale-downloader-linux-amd64 /opt/hytale/hytale-downloader \
    && chmod +x /opt/hytale/hytale-downloader \
    && rm -f /tmp/hytale-downloader.zip \
    && microdnf clean all

RUN mkdir -p /data

WORKDIR /data

ENV ASSETS_PATH="/assets/Assets.zip" \
    ASSETS_DIR="/assets" \
    ASSETS_AUTO_UPDATE="false" \
    ASSETS_PATCHLINE="" \
    ASSETS_VERSION_FILE="/assets/assets.version" \
    HYTALE_DOWNLOADER_PATH="/opt/hytale/hytale-downloader" \
    SERVER_DIR="/assets/server" \
    SERVER_JAR="/assets/server/HytaleServer.jar" \
    SERVER_AOT="/assets/server/HytaleServer.aot" \
    JAVA_OPTS="" \
    HYTALE_OPTS=""

EXPOSE 5520/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
