FROM eclipse-temurin:25-ubi10-minimal

WORKDIR /opt/hytale

COPY HytaleServer.jar .
COPY HytaleServer.aot .

RUN mkdir -p /data

WORKDIR /data

ENV ASSETS_PATH="/assets/Assets.zip" \
    JAVA_OPTS="" \
    HYTALE_OPTS=""

EXPOSE 5520/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
