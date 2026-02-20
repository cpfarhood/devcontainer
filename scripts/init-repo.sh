#!/bin/bash
# Initialize repository and start Happy Coder
set -e

echo "=== Repository Initialization ==="

# Check if GITHUB_REPO is set
if [ -z "$GITHUB_REPO" ]; then
    echo "GITHUB_REPO not set, skipping repository clone"
    WORKSPACE_DIR="/workspace/default"
    mkdir -p "$WORKSPACE_DIR"
else
    # Parse repo name from URL
    REPO_NAME=$(basename "$GITHUB_REPO" .git)
    WORKSPACE_DIR="/workspace/$REPO_NAME"

    echo "Repository: $GITHUB_REPO"
    echo "Target directory: $WORKSPACE_DIR"

    # Check if repo already exists
    if [ -d "$WORKSPACE_DIR/.git" ]; then
        echo "Repository already exists, pulling latest changes..."
        cd "$WORKSPACE_DIR"

        # Configure git to use token if provided
        if [ -n "$GITHUB_TOKEN" ]; then
            git config credential.helper store
            echo "https://oauth2:${GITHUB_TOKEN}@github.com" > /home/.git-credentials
            chmod 600 /home/.git-credentials
        fi

        git pull || echo "Pull failed, continuing anyway..."
    else
        echo "Cloning repository..."
        mkdir -p "$(dirname "$WORKSPACE_DIR")"

        # Clone with token if provided
        if [ -n "$GITHUB_TOKEN" ]; then
            # Replace https://github.com/ with https://oauth2:token@github.com/
            CLONE_URL=$(echo "$GITHUB_REPO" | sed "s|https://github.com/|https://oauth2:${GITHUB_TOKEN}@github.com/|")
            git clone "$CLONE_URL" "$WORKSPACE_DIR"

            # Configure credentials for future use
            git config --global credential.helper store
            echo "https://oauth2:${GITHUB_TOKEN}@github.com" > /home/.git-credentials
            chmod 600 /home/.git-credentials
        else
            git clone "$GITHUB_REPO" "$WORKSPACE_DIR"
        fi
    fi
fi

# Set ownership using numeric IDs (username may not exist yet in baseimage-gui)
RUN_UID="${USER_ID:-1000}"
RUN_GID="${GROUP_ID:-1000}"
chown -R "$RUN_UID:$RUN_GID" "$WORKSPACE_DIR"

# Ensure home directory exists on the PVC (may be absent on a fresh volume)
mkdir -p "$HOME"
chown "$RUN_UID:$RUN_GID" "$HOME"

# Start Happy Coder daemon
echo "Starting Happy Coder..."
cd "$WORKSPACE_DIR"

happy daemon start

echo "Happy Coder daemon started"

# Export workspace directory for startapp.sh
echo "$WORKSPACE_DIR" > /tmp/workspace-dir

echo "=== Initialization Complete ==="
