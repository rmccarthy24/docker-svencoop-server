FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# SteamCMD and the Sven Co-op server are 32-bit, so enable i386 multiarch on amd64
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl tar locales \
      libc6-i386 lib32gcc-s1 lib32stdc++6 \
 && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    DATA_DIR=/serverdata \
    STEAMCMD_DIR=/serverdata/steamcmd \
    SERVER_DIR=/serverdata/serverfiles \
    GAME_ID=276060 \
    GAME_PARAMS="+maxplayers 12 +map osprey +log on" \
    GAME_PORT=27015 \
    VALIDATE="" \
    PUID=99 \
    PGID=100 \
    STEAM_USER="" \
    STEAM_PASSWORD=""

RUN groupadd -o -g ${PGID} steam \
 && useradd -o -u ${PUID} -g ${PGID} -d ${DATA_DIR} -s /bin/bash steam \
 && mkdir -p ${STEAMCMD_DIR} ${SERVER_DIR} \
 && chown -R steam:steam ${DATA_DIR}

COPY scripts/start-server.sh /opt/scripts/start-server.sh
RUN chmod 755 /opt/scripts/start-server.sh

EXPOSE 27015/tcp 27015/udp
VOLUME ["/serverdata/steamcmd", "/serverdata/serverfiles"]

# Starts as root to fix volume ownership, then drops to the steam user
ENTRYPOINT ["/opt/scripts/start-server.sh"]