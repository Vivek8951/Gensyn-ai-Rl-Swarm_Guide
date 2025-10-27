FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    curl \
    wget \
    screen \
    git \
    lsof \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g yarn

WORKDIR /app

RUN git clone https://github.com/gensyn-ai/rl-swarm.git . && \
    python3 -m venv .venv

ENV PATH="/app/.venv/bin:${PATH}"

RUN chmod +x /app/run_rl_swarm.sh

EXPOSE 3000

CMD ["/bin/bash", "-c", "source /app/.venv/bin/activate && /app/run_rl_swarm.sh"]
