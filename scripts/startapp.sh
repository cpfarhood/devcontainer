#!/bin/bash
# Start application script for baseimage-gui
set -e

echo "=== Starting Antigravity Dev Container ==="

# Initialize repository and Happy Coder
/usr/local/bin/init-repo

# Get workspace directory
if [ -f /tmp/workspace-dir ]; then
    WORKSPACE_DIR=$(cat /tmp/workspace-dir)
else
    WORKSPACE_DIR="/workspace/default"
fi

IDE="${IDE:-vscode}"
echo "IDE mode: $IDE"
echo "Workspace: $WORKSPACE_DIR"

case "$IDE" in
    antigravity)
        echo "Opening Google Antigravity in: $WORKSPACE_DIR"
        # --no-sandbox is required for Electron apps in Docker (no kernel sandbox available).
        # Explicit --user-data-dir and --extensions-dir pin config to the home PVC so
        # settings and the setup wizard state survive pod restarts.
        exec antigravity --no-sandbox \
            --user-data-dir "$HOME/.config/antigravity" \
            --extensions-dir "$HOME/.antigravity/extensions" \
            --new-window --wait "$WORKSPACE_DIR"
        ;;
    none)
        echo "IDE=none: no IDE launched, keeping container alive."
        exec sleep infinity
        ;;
    *)
        echo "Opening VSCode in: $WORKSPACE_DIR"
        exec code --new-window --wait "$WORKSPACE_DIR"
        ;;
esac
