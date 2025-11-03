FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    sudo \
    python3 \
    python3-venv \
    python3-pip \
    curl \
    wget \
    screen \
    git \
    lsof \
    ufw \
    ca-certificates \
    gnupg \
    apt-transport-https \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && \
    rm cloudflared-linux-amd64.deb

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list > /dev/null && \
    apt-get update && \
    apt-get install -y yarn && \
    rm -rf /var/lib/apt/lists/*


RUN python3 --version && \
    node -v && \
    npm -v && \
    yarn -v

RUN useradd -m -s /bin/bash rlswarm && \
    echo "rlswarm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER rlswarm
WORKDIR /home/rlswarm

ENV VIRTUAL_ENV="/home/rlswarm/rl-swarm/.venv"
ENV PATH="/home/rlswarm/rl-swarm/.venv/bin:${PATH}"

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
