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

RUN corepack enable && corepack prepare yarn@stable --activate

RUN python3 --version && \
    node -v && \
    npm -v && \
    yarn -v

RUN useradd -m -s /bin/bash rlswarm && \
    echo "rlswarm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER rlswarm
WORKDIR /home/rlswarm

RUN git clone https://github.com/gensyn-ai/rl-swarm.git rl-swarm

WORKDIR /home/rlswarm/rl-swarm

RUN python3 -m venv .venv

RUN bash -c "source .venv/bin/activate && pip install --upgrade pip"

RUN if [ -f run_rl_swarm.sh ]; then chmod +x run_rl_swarm.sh; fi

ENV PATH="/home/rlswarm/rl-swarm/.venv/bin:${PATH}"
ENV VIRTUAL_ENV="/home/rlswarm/rl-swarm/.venv"

EXPOSE 3000

CMD ["/bin/bash", "-c", "echo ''; echo '╔═══════════════════════════════════════════════════════════╗'; echo '║  RL-Swarm is starting...                                  ║'; echo '║  Access login at: http://localhost:3000                   ║'; echo '║  Or run: ./deploy.sh login                                ║'; echo '╚═══════════════════════════════════════════════════════════╝'; echo ''; source .venv/bin/activate && exec ./run_rl_swarm.sh"]
