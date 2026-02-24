#!/bin/bash
# Initialize repository
set -e

echo "=== Repository Initialization ==="

# Set up basic git configuration
echo "Configuring git user settings..."
# Use environment variables if provided, otherwise use defaults
GIT_USER_NAME="${GIT_USER_NAME:-DevContainer User}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-devcontainer@example.com}"

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# Set up git credentials early if GITHUB_TOKEN is provided
# This ensures all git operations have proper authentication
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Setting up git credentials..."
    # Configure git to use credential store globally
    git config --global credential.helper store

    # Create or update the credentials file
    CREDENTIALS_FILE="/config/userdata/.git-credentials"
    mkdir -p "$(dirname "$CREDENTIALS_FILE")"

    # Support multiple git hosting providers
    # GitHub supports both oauth2 and token as username
    echo "https://oauth2:${GITHUB_TOKEN}@github.com" > "$CREDENTIALS_FILE"
    echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" >> "$CREDENTIALS_FILE"
    echo "https://token:${GITHUB_TOKEN}@github.com" >> "$CREDENTIALS_FILE"

    # GitLab format (if same token works)
    if [ -n "$GITLAB_HOST" ]; then
        echo "https://oauth2:${GITHUB_TOKEN}@${GITLAB_HOST}" >> "$CREDENTIALS_FILE"
    fi

    chmod 600 "$CREDENTIALS_FILE"

    # Also create a symlink in the home directory if it doesn't exist
    # This handles cases where git might look in different locations
    if [ ! -f "$HOME/.git-credentials" ] && [ "$HOME" != "/config/userdata" ]; then
        ln -sf "$CREDENTIALS_FILE" "$HOME/.git-credentials"
    fi

    echo "Git credentials configured"
else
    # Even without a token, ensure git has a proper credential helper configured
    # This prevents errors when credentials are added later
    echo "No GITHUB_TOKEN provided, configuring basic git settings..."
    git config --global credential.helper store

    # Create an empty credentials file with proper permissions
    CREDENTIALS_FILE="/config/userdata/.git-credentials"
    mkdir -p "$(dirname "$CREDENTIALS_FILE")"
    touch "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"

    # Create symlink if needed
    if [ ! -f "$HOME/.git-credentials" ] && [ "$HOME" != "/config/userdata" ]; then
        ln -sf "$CREDENTIALS_FILE" "$HOME/.git-credentials"
    fi
fi

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
        git pull || echo "Pull failed, continuing anyway..."
    else
        echo "Cloning repository..."
        mkdir -p "$(dirname "$WORKSPACE_DIR")"

        # Clone with token if provided
        if [ -n "$GITHUB_TOKEN" ]; then
            # Replace https://github.com/ with https://oauth2:token@github.com/
            CLONE_URL=$(echo "$GITHUB_REPO" | sed "s|https://github.com/|https://oauth2:${GITHUB_TOKEN}@github.com/|")
            git clone "$CLONE_URL" "$WORKSPACE_DIR"
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


# Export workspace directory for startapp.sh
echo "$WORKSPACE_DIR" > /tmp/workspace-dir

echo "=== Initialization Complete ==="
