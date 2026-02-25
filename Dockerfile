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

# Install Node.js LTS (required by Happy Coder)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Happy Coder globally via npm (stable, rarely changes)
RUN npm install -g happy-coder

# Install Claude Code native binary (npm wrapper breaks remote control)
RUN curl -fsSL https://claude.ai/install.sh | bash && claude --version

# Install OpenCode AI coding agent
RUN OPENCODE_VERSION=$(curl -sL https://api.github.com/repos/opencode-ai/opencode/releases/latest | jq -r '.tag_name') && \
    curl -fsSL "https://github.com/opencode-ai/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-x86_64.tar.gz" | \
    tar -xz -C /usr/local/bin opencode && \
    chmod +x /usr/local/bin/opencode

# Install Crush AI coding agent (OpenCode successor by Charm)
RUN CRUSH_VERSION=$(curl -sL https://api.github.com/repos/charmbracelet/crush/releases/latest | jq -r '.tag_name' | sed 's/^v//') && \
    curl -fsSL "https://github.com/charmbracelet/crush/releases/download/v${CRUSH_VERSION}/crush_${CRUSH_VERSION}_Linux_x86_64.tar.gz" -o /tmp/crush.tar.gz && \
    tar -xzf /tmp/crush.tar.gz -C /tmp && \
    mv /tmp/crush_${CRUSH_VERSION}_Linux_x86_64/crush /usr/local/bin/crush && \
    chmod +x /usr/local/bin/crush && \
    rm -rf /tmp/crush*

# Install Helm CLI for Kubernetes chart management
ARG HELM_VERSION=3.17.1
RUN curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | \
    tar -xz --strip-components=1 -C /usr/local/bin linux-amd64/helm && \
    chmod +x /usr/local/bin/helm

# Install VSCode (using Microsoft's current recommended setup)
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg && \
    install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg && \
    rm -f /tmp/microsoft.gpg && \
    printf 'Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: /usr/share/keyrings/microsoft.gpg\n' \
      > /etc/apt/sources.list.d/vscode.sources && \
    apt-get update && \
    apt-get install -y code && \
    rm -rf /var/lib/apt/lists/*

# Install Google Antigravity IDE
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
      gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
      > /etc/apt/sources.list.d/antigravity.list && \
    # Clear package cache to force fresh repository data
    rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    # Show available versions for debugging
    apt-cache policy antigravity && \
    # Install latest version
    apt-get install -y --no-install-recommends antigravity && \
    # Display installed version
    dpkg -l | grep antigravity && \
    rm -rf /var/lib/apt/lists/*

# Pre-configure Antigravity to skip onboarding/setup on first run
RUN mkdir -p /etc/skel/.config/antigravity/User/globalStorage && \
    echo '{"antigravityUnifiedStateSync.seenNuxOneTimeMigration": true, "antigravityUnifiedStateSync.browserOnboarding.completed": true, "antigravityUnifiedStateSync.hasOnboardingCompleted": true, "browserOnboarding.hasSeenWelcome": true, "antigravityUnifiedStateSync.browserPreferences.hasAddedLocalhostToAllowlist": true, "antigravityUnifiedStateSync.oauthToken.hasLegacyMigrated": true, "antigravityUnifiedStateSync.auth.tokenSyncEnabled": true, "antigravityUnifiedStateSync.auth.cloudSyncEnabled": true, "theme": "vs-dark"}' \
      > /etc/skel/.config/antigravity/User/globalStorage/storage.json && \
    echo '{"workbench.startupEditor": "none", "workbench.welcomePage.walkthroughs.openOnInstall": false, "workbench.tips.enabled": false, "extensions.ignoreRecommendations": true, "telemetry.telemetryLevel": "off", "update.mode": "none", "extensions.autoUpdate": false, "extensions.autoCheckUpdates": false, "workbench.enableExperiments": true, "workbench.settings.enableNaturalLanguageSearch": true, "antigravity.onboarding.completed": true, "antigravity.browserOnboarding.completed": true, "antigravity.setup.completed": true, "antigravity.ai.enabled": true, "antigravity.ai.autoComplete.enabled": true, "antigravity.ai.chat.enabled": true, "antigravity.ai.codeActions.enabled": true, "antigravity.ai.explainCode.enabled": true, "antigravity.ai.generateCode.enabled": true, "antigravity.ai.optimizeCode.enabled": true, "antigravity.ai.autoSuggest.enabled": true, "antigravity.telemetry.crashReporter": "on", "antigravity.ai.acceptTerms": true, "antigravity.auth.syncState": true, "antigravity.auth.enableTokenSync": true, "antigravity.ai.enableCloudSync": true, "antigravity.settings.sync": true}' \
      > /etc/skel/.config/antigravity/User/settings.json && \
    # Validate Antigravity installation
    /usr/share/antigravity/antigravity --version || echo "WARNING: Antigravity version check failed"

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
# Copy serverless scripts (conditional execution)
COPY --chmod=755 serverless/scripts/dynamic-init-repo.sh /usr/local/bin/dynamic-init-repo
COPY --chmod=755 serverless/scripts/serverless-startapp.sh /usr/local/bin/serverless-startapp
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
