FROM debian:trixie-slim

LABEL name="santa-claudes-workshop"
LABEL version="0.1"

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd -g ${GROUP_ID} rootless && \
    useradd -u ${USER_ID} -g rootless -m -s /bin/bash rootless

# Base packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        gnupg \
        libssl3 \
        locales \
        openssl \
        socat \
        iproute2 \
        nano \
        git \
        bash-completion \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Docker repo
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
        https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list

# Docker CLI + Compose + Buildx
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce-cli \
        docker-compose-plugin \
        docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

COPY util/start-workshop.sh /usr/local/bin/start-workshop.sh
RUN chmod +x /usr/local/bin/start-workshop.sh

WORKDIR /home/rootless/workshop
RUN chown rootless:rootless /home/rootless/workshop

USER rootless

CMD ["/usr/local/bin/start-workshop.sh"]