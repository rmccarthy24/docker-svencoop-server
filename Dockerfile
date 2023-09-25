FROM debian:stable-slim

RUN apt-get update && apt-get install --no-install-recommends -y \
        wget curl ca-certificates libgcc1 libstdc++6 libssl1.1 libstdc++6 locales locales-all zlib1g libc6 libstdc++6 ca-certificates libgcc1 libstdc++6 zlib1g curl file bzip2 gzip unzip libssl1.1 libxrandr-dev libxi-dev libgl1-mesa-glx libxtst6 libusb-1.0.0 libxxf86vm1 libglu1-mesa libopenal1 libgtk2.0-0 libsm6 libdbus-glib-1-2 libnm-glib4 libnm-util2 libudev-dev libudev-dev libpulse0 && \
    apt-get clean && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* && \
    ln -s /lib/linux-gnu/libudev.so.1 /lib/linux-gnu/libudev.so.0

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV DATA_DIR="/serverdata"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"
ENV SERVER_DIR="${DATA_DIR}/serverfiles"
ENV GAME_ID="276060"
ENV GAME_NAME="svencoop"
ENV GAME_PARAMS="template"
ENV GAME_PORT=27015
ENV VALIDATE=""
ENV UID=99
ENV GID=100
ENV USERNAME=""
ENV PASSWRD=""

ADD /scripts/ /opt/scripts/
RUN mkdir $DATA_DIR && \
    mkdir $STEAMCMD_DIR && \
    mkdir $SERVER_DIR && \
    useradd -d $DATA_DIR -s /bin/bash --uid $UID --gid $GID steam && \
    chown -R steam $DATA_DIR && \
    ulimit -n 2048 && \
    chmod -R 770 /opt/scripts/ && \
    chown -R steam /opt/scripts

USER steam

#Server Start
ENTRYPOINT ["/opt/scripts/start-server.sh"]
