#!/bin/bash

# Serverless-aware startup script for devcontainer
# This replaces the standard /startapp.sh when in serverless mode

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVERLESS-START: $*" >&2
}

log "Starting serverless devcontainer..."
log "Mode: ${SERVERLESS_MODE:-traditional}"
log "IDE: ${IDE:-vscode}"

# Wait for HTTP headers to be available (in case of init container pattern)
# In Knative, the headers should be available immediately as env vars
sleep 2

# Check if we're in serverless mode with dynamic routing
if [[ "$SERVERLESS_MODE" == "true" && "$DYNAMIC_GITHUB_ROUTING" == "true" ]]; then
    log "Dynamic GitHub routing enabled"

    # In Knative, HTTP headers become environment variables with HTTP_ prefix
    # But we also check for the unprefixed versions set by proxies
    AVAILABLE_VARS=$(env | grep -E "(GITHUB|AUTHENTIK|X_)" | sort)
    if [[ -n "$AVAILABLE_VARS" ]]; then
        log "Available routing variables:"
        echo "$AVAILABLE_VARS" | while read -r var; do
            log "  $var"
        done
    else
        log "No routing variables found, checking for alternatives..."
        # Check if there's a file with the repo info
        if [[ -f "/tmp/github-repo" ]]; then
            export GITHUB_REPO=$(cat /tmp/github-repo)
            log "Found repo file: $GITHUB_REPO"
        else
            log "ERROR: No GitHub repository information available"
            log "Expected routing headers or /tmp/github-repo file"
            exit 1
        fi
    fi

    # Use the dynamic initialization script
    source /usr/local/bin/dynamic-init-repo
else
    log "Using standard initialization..."
    # Use the standard initialization
    source /usr/local/bin/init-repo
fi

# At this point, WORKSPACE_DIR should be set by the init script
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
log "Working directory: $WORKSPACE_DIR"

# Ensure we're in the workspace directory
cd "$WORKSPACE_DIR"

# Launch the appropriate IDE based on the IDE environment variable
case "${IDE:-vscode}" in
    "vscode")
        log "Starting VSCode..."
        exec code --new-window --wait "$WORKSPACE_DIR"
        ;;
    "antigravity")
        log "Starting Antigravity..."
        exec antigravity \
            --no-sandbox \
            --user-data-dir ~/.config/antigravity \
            --disable-dev-shm-usage \
            --disable-gpu \
            --disable-features=VizDisplayCompositor \
            --new-window \
            "$WORKSPACE_DIR"
        ;;
    "none")
        log "No IDE requested, keeping container alive..."
        exec sleep infinity
        ;;
    *)
        log "ERROR: Unknown IDE type: $IDE"
        log "Valid options: vscode, antigravity, none"
        exit 1
        ;;
esac