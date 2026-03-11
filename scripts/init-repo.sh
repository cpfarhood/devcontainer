#!/bin/bash
# Initialize repository
set -e

echo "=== Repository Initialization ==="

# Ensure home directory exists on the PVC before any git operations
# (git config --global writes to $HOME/.gitconfig, which fails on a fresh volume)
RUN_UID="${USER_ID:-1000}"
RUN_GID="${GROUP_ID:-1000}"
mkdir -p "$HOME"
chown "$RUN_UID:$RUN_GID" "$HOME"

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

# Build list of repositories to clone
REPOS=()
if [ -n "$GITHUB_REPOS" ]; then
    # GITHUB_REPOS is a comma-separated list (takes precedence over GITHUB_REPO)
    IFS=',' read -ra RAW_REPOS <<< "$GITHUB_REPOS"
    for repo in "${RAW_REPOS[@]}"; do
        repo="$(echo "$repo" | xargs)"  # trim whitespace
        [ -n "$repo" ] && REPOS+=("$repo")
    done
elif [ -n "$GITHUB_REPO" ]; then
    REPOS+=("$GITHUB_REPO")
fi

if [ ${#REPOS[@]} -eq 0 ]; then
    echo "No repositories configured, skipping clone"
    WORKSPACE_DIR="/workspace/default"
    mkdir -p "$WORKSPACE_DIR"
else
    CLONED_DIRS=()
    for REPO_URL in "${REPOS[@]}"; do
        REPO_NAME=$(basename "$REPO_URL" .git)
        REPO_DIR="/workspace/$REPO_NAME"

        echo "Repository: $REPO_URL"
        echo "Target directory: $REPO_DIR"

        if [ -d "$REPO_DIR/.git" ]; then
            echo "Repository already exists, pulling latest changes..."
            cd "$REPO_DIR"
            git pull || echo "Pull failed, continuing anyway..."
        else
            echo "Cloning repository..."
            mkdir -p "$(dirname "$REPO_DIR")"

            if [ -n "$GITHUB_TOKEN" ]; then
                CLONE_URL=$(echo "$REPO_URL" | sed "s|https://github.com/|https://oauth2:${GITHUB_TOKEN}@github.com/|")
                git clone "$CLONE_URL" "$REPO_DIR"
            else
                git clone "$REPO_URL" "$REPO_DIR"
            fi
        fi

        CLONED_DIRS+=("$REPO_DIR")
    done

    if [ ${#CLONED_DIRS[@]} -eq 1 ]; then
        # Single repo — open directory directly (same as legacy behavior)
        WORKSPACE_DIR="${CLONED_DIRS[0]}"
    else
        # Multiple repos — generate a multi-root workspace file
        WS_FILE="/workspace/workspace.code-workspace"
        printf '{\n  "folders": [\n' > "$WS_FILE"
        for i in "${!CLONED_DIRS[@]}"; do
            printf '    {"path": "%s"}' "${CLONED_DIRS[$i]}" >> "$WS_FILE"
            if [ "$i" -lt $(( ${#CLONED_DIRS[@]} - 1 )) ]; then
                printf ',\n' >> "$WS_FILE"
            else
                printf '\n' >> "$WS_FILE"
            fi
        done
        printf '  ],\n  "settings": {}\n}\n' >> "$WS_FILE"
        WORKSPACE_DIR="$WS_FILE"
        echo "Generated multi-root workspace: $WS_FILE"
    fi
fi

# Set ownership using numeric IDs (username may not exist yet in baseimage-gui)
RUN_UID="${USER_ID:-1000}"
RUN_GID="${GROUP_ID:-1000}"
for dir in "${CLONED_DIRS[@]}"; do
    chown -R "$RUN_UID:$RUN_GID" "$dir"
done
if [ -n "$WS_FILE" ] && [ -f "$WS_FILE" ]; then
    chown "$RUN_UID:$RUN_GID" "$WS_FILE"
fi
# Ensure default workspace dir ownership if no repos were cloned
if [ ${#REPOS[@]} -eq 0 ]; then
    chown -R "$RUN_UID:$RUN_GID" "$WORKSPACE_DIR"
fi

# Seed Claude Code settings if missing (disable auto-updater in Docker)
if [ ! -f "$HOME/.claude/settings.json" ]; then
    mkdir -p "$HOME/.claude"
    echo '{"env":{"DISABLE_AUTOUPDATER":"1"}}' > "$HOME/.claude/settings.json"
    chown -R "$RUN_UID:$RUN_GID" "$HOME/.claude"
fi

# Export workspace directory for startapp.sh
echo "$WORKSPACE_DIR" > /tmp/workspace-dir

echo "=== Initialization Complete ==="
