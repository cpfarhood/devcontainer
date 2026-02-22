FROM jlesage/baseimage-gui:ubuntu-22.04-v4

# Set environment variables
ENV APP_NAME="Dev Container" \
    KEEP_APP_RUNNING=1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    SECURE_CONNECTION=1 \
    USER_ID=1000 \
    GROUP_ID=1000 \
    CLAUDE_USER=user

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

# Install Chrome and xdg-utils (needed for xdg-open to work in VNC)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable xdg-utils && \
    rm -rf /var/lib/apt/lists/*

# Chrome wrapper: adds flags required for running inside a Docker container.
# xdg-open (used by Claude Code on Linux) respects $BROWSER, so pointing it
# here ensures the OAuth popup works without manual --no-sandbox invocations.
# Cleans up crash lock files and suppresses the crash-restore bubble so that
# sessions/cookies survive unclean pod shutdowns (SIGKILL).
RUN printf '#!/bin/bash\n\
CHROME_DIR="/config/userdata/.config/google-chrome"\n\
mkdir -p "$CHROME_DIR"\n\
# Remove stale lock files left by unclean container shutdown\n\
rm -f "$CHROME_DIR/SingletonLock" "$CHROME_DIR/SingletonSocket" "$CHROME_DIR/SingletonCookie"\n\
# Mark the previous session as clean so Chrome does not clear cookies\n\
PREFS="$CHROME_DIR/Default/Preferences"\n\
if [ -f "$PREFS" ]; then\n\
  sed -i '\''s/"exit_type":"Crashed"/"exit_type":"Normal"/g; s/"exited_cleanly":false/"exited_cleanly":true/g'\'' "$PREFS"\n\
fi\n\
exec /usr/bin/google-chrome-stable \\\n\
  --no-sandbox \\\n\
  --disable-dev-shm-usage \\\n\
  --disable-gpu \\\n\
  --disable-session-crashed-bubble \\\n\
  --user-data-dir="$CHROME_DIR" \\\n\
  "$@"\n' > /usr/local/bin/google-chrome && \
    chmod +x /usr/local/bin/google-chrome

# Install Node.js (LTS version for Happy Coder)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Happy Coder and Claude Code globally
RUN npm install -g happy-coder @anthropic-ai/claude-code

# Install VSCode
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# Install Google Antigravity IDE
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
      gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
      > /etc/apt/sources.list.d/antigravity.list && \
    apt-get update && \
    apt-get install -y antigravity && \
    rm -rf /var/lib/apt/lists/*

# Install OpenSSH server (for SSH IDE mode)
RUN apt-get update && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Create user user with specific UID/GID
RUN groupadd -g 1000 user && \
    useradd -u 1000 -g 1000 -m -s /bin/bash user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create workspace directory
RUN mkdir -p /workspace && \
    chown -R user:user /workspace

# Copy startup scripts
COPY --chmod=755 scripts/startapp.sh /startapp.sh
COPY --chmod=755 scripts/init-repo.sh /usr/local/bin/init-repo
# Fix app user shell after baseimage-gui creates it at runtime
COPY --chmod=755 scripts/cont-init-user.sh /etc/cont-init.d/20-fix-user-shell.sh
COPY --chmod=755 scripts/cont-init-sshd.sh /etc/cont-init.d/25-start-sshd.sh

# Set working directory
WORKDIR /workspace

# Configure container to run as user user
ENV HOME=/config/userdata \
    USER=user \
    BROWSER=/usr/local/bin/google-chrome

# Expose VNC port (baseimage-gui default)
EXPOSE 5800

# Set app name for baseimage-gui
RUN set-cont-env APP_NAME "Dev Container"
