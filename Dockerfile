FROM jlesage/baseimage-gui:ubuntu-22.04-v4

# Set environment variables
ENV APP_NAME="Antigravity Dev Container" \
    KEEP_APP_RUNNING=1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    SECURE_CONNECTION=1 \
    USER_ID=1000 \
    GROUP_ID=1000 \
    CLAUDE_USER=claude

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    ca-certificates \
    git \
    build-essential \
    python3 \
    python3-pip \
    jq \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js (LTS version for Happy Coder)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Happy Coder globally
RUN npm install -g happy-coder

# Install Antigravity (Google's Project IDX / Cloud Code alternative)
# Note: Antigravity might be packaged differently - adjust as needed
# For now, we'll use VSCode with Project IDX extensions as a placeholder
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# Create claude user with specific UID/GID
RUN groupadd -g 1000 claude && \
    useradd -u 1000 -g 1000 -m -s /bin/bash claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create workspace directory
RUN mkdir -p /workspace && \
    chown -R claude:claude /workspace

# Copy startup script
COPY --chmod=755 scripts/startapp.sh /startapp.sh
COPY --chmod=755 scripts/init-repo.sh /usr/local/bin/init-repo

# Set working directory
WORKDIR /workspace

# Configure container to run as claude user
ENV HOME=/home/claude \
    USER=claude

# Expose VNC port (baseimage-gui default)
EXPOSE 5800

# Set app name for baseimage-gui
RUN set-cont-env APP_NAME "Antigravity"
