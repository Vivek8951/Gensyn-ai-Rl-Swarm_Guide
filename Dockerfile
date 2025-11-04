FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

# Install system dependencies
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
    net-tools \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list > /dev/null && \
    apt-get update && \
    apt-get install -y yarn && \
    rm -rf /var/lib/apt/lists/*

# Install cloudflared
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && \
    rm cloudflared-linux-amd64.deb

# Verify installations
RUN python3 --version && \
    node -v && \
    npm -v && \
    yarn -v && \
    cloudflared --version

# Create user and directories
RUN useradd -m -s /bin/bash rlswarm && \
    echo "rlswarm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to rlswarm user
USER rlswarm
WORKDIR /home/rlswarm

# PRE-BUILD PHASE: Everything built into image during Docker build
# Pre-clone RL-Swarm repository
RUN echo "📦 PRE-BUILD: Cloning RL-Swarm repository..." && \
    git clone https://github.com/gensyn-ai/rl-swarm.git rl-swarm && \
    cd rl-swarm && \
    echo "✅ Repository cloned successfully" && \
    echo "Current commit: $(git rev-parse --short HEAD)"

# Pre-setup Python virtual environment
RUN cd rl-swarm && \
    echo "🐍 PRE-BUILD: Setting up Python virtual environment..." && \
    python3 -m venv .venv && \
    . .venv/bin/activate && \
    pip install --upgrade pip && \
    echo "✅ Virtual environment created"

# Pre-install Python requirements
RUN cd rl-swarm && \
    if [ -f requirements.txt ]; then \
        echo "📦 PRE-BUILD: Installing Python requirements..." && \
        . .venv/bin/activate && \
        pip install -r requirements.txt && \
        echo "✅ Python requirements installed"; \
    else \
        echo "⚠️  No requirements.txt found"; \
    fi

# Pre-install Node.js dependencies
RUN cd rl-swarm && \
    echo "📦 PRE-BUILD: Installing Node.js dependencies..." && \
    yarn install && \
    echo "✅ Node.js dependencies installed" && \
    echo "Node modules size: $(du -sh node_modules | cut -f1)" && \
    echo "Packages count: $(ls node_modules 2>/dev/null | wc -l)"

# Pre-make scripts executable
RUN cd rlswarm && \
    chmod +x run_rl_swarm.sh && \
    echo "✅ Scripts made executable"

# Create setup completion marker
RUN touch /home/rlswarm/rl-swarm/.setup-complete && \
    echo "✅ PRE-BUILD SETUP COMPLETED!" && \
    echo "   • Git repository: Pre-cloned" && \
    echo "   • Node.js modules: Pre-installed" && \
    echo "   • Virtual environment: Pre-created" && \
    echo "   • Setup time: Instant (no downloads needed)"

# Set up environment variables for pre-built image
ENV VIRTUAL_ENV="/home/rlswarm/rl-swarm/.venv"
ENV PATH="/home/rlswarm/rl-swarm/.venv/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV AUTO_TUNNEL=true
ENV REMOTE_ACCESS=true
ENV PREBUILT=true
ENV SETUP_COMPLETE=true

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# Copy pre-built optimized entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["./run_rl_swarm.sh"]
