#!/bin/bash

# Dynamic GitHub repository initialization for serverless mode
# This script extracts the GitHub repo from HTTP headers set by the routing proxy

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DYNAMIC-INIT: $*" >&2
}

log "Starting dynamic repository initialization..."

# In serverless mode, we expect the routing proxy to have set these environment variables
# from the HTTP headers. If running standalone, fallback to GITHUB_REPO env var.

if [[ "$SERVERLESS_MODE" == "true" ]]; then
    log "Serverless mode detected"

    # The routing proxy should have set these via HTTP headers -> env vars
    # Check if we have the GitHub repo from the X-GitHub-Repo header
    if [[ -n "$HTTP_X_GITHUB_REPO" ]]; then
        GITHUB_REPO="$HTTP_X_GITHUB_REPO"
        log "Using GitHub repo from header: $GITHUB_REPO"
    elif [[ -n "$X_GITHUB_REPO" ]]; then
        GITHUB_REPO="$X_GITHUB_REPO"
        log "Using GitHub repo from X-GitHub-Repo: $GITHUB_REPO"
    else
        # Try to extract from a file written by an init container or sidecar
        if [[ -f "/tmp/github-repo" ]]; then
            GITHUB_REPO=$(cat /tmp/github-repo)
            log "Using GitHub repo from file: $GITHUB_REPO"
        else
            log "ERROR: No GitHub repository specified in serverless mode"
            log "Expected HTTP_X_GITHUB_REPO or X_GITHUB_REPO header from routing proxy"
            exit 1
        fi
    fi

    # Extract user info if available
    if [[ -n "$HTTP_X_AUTHENTIK_USERNAME" ]]; then
        export GIT_USER_NAME="${HTTP_X_AUTHENTIK_NAME:-$HTTP_X_AUTHENTIK_USERNAME}"
        export GIT_USER_EMAIL="${HTTP_X_AUTHENTIK_EMAIL:-${HTTP_X_AUTHENTIK_USERNAME}@devcontainer.local}"
        log "Using Authentik user: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    fi
else
    log "Traditional mode - using GITHUB_REPO environment variable"
    if [[ -z "$GITHUB_REPO" ]]; then
        log "ERROR: GITHUB_REPO environment variable is required"
        exit 1
    fi
fi

# Validate the GitHub repo URL
if [[ ! "$GITHUB_REPO" =~ ^https://github\.com/[^/]+/[^/]+/?$ ]]; then
    log "ERROR: Invalid GitHub repository URL: $GITHUB_REPO"
    log "Expected format: https://github.com/owner/repo"
    exit 1
fi

# Extract owner and repo name for workspace directory
REPO_OWNER=$(echo "$GITHUB_REPO" | sed 's|https://github.com/\([^/]*\)/.*|\1|')
REPO_NAME=$(echo "$GITHUB_REPO" | sed 's|https://github.com/[^/]*/\([^/]*\)/?|\1|')
WORKSPACE_DIR="/workspace/${REPO_OWNER}-${REPO_NAME}"

log "Repository: $GITHUB_REPO"
log "Owner: $REPO_OWNER"
log "Name: $REPO_NAME"
log "Workspace: $WORKSPACE_DIR"

# Configure git user (use defaults if not set via Authentik)
GIT_USER_NAME="${GIT_USER_NAME:-DevContainer User}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-devcontainer@example.com}"

log "Configuring git user: $GIT_USER_NAME <$GIT_USER_EMAIL>"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# Configure git credentials if GitHub token is available
if [[ -n "$GITHUB_TOKEN" ]]; then
    log "Configuring GitHub credentials..."
    git config --global credential.helper store
    echo "https://oauth2:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
    chmod 600 ~/.git-credentials
else
    log "No GitHub token provided - using public access only"
fi

# Create workspace directory
mkdir -p "$(dirname "$WORKSPACE_DIR")"
cd "$(dirname "$WORKSPACE_DIR")"

# Clone the repository
if [[ -d "$WORKSPACE_DIR" ]]; then
    log "Repository directory exists, pulling latest changes..."
    cd "$WORKSPACE_DIR"
    git pull --ff-only || {
        log "WARNING: Could not fast-forward, repository may have diverged"
        log "Continuing with existing state..."
    }
else
    log "Cloning repository..."
    git clone "$GITHUB_REPO" "$WORKSPACE_DIR" || {
        log "ERROR: Failed to clone repository $GITHUB_REPO"
        log "This may be a private repository or the URL may be incorrect"
        exit 1
    }
    cd "$WORKSPACE_DIR"
fi

# Set the workspace directory for the IDE
export WORKSPACE_DIR

log "Repository initialization complete!"
log "Workspace directory: $WORKSPACE_DIR"

# Change to the workspace directory so the IDE opens in the right place
cd "$WORKSPACE_DIR"

# Export variables for the parent script
export GITHUB_REPO
export WORKSPACE_DIR
export REPO_OWNER
export REPO_NAME