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

echo "Opening Antigravity in: $WORKSPACE_DIR"

# Start Antigravity (VSCode) in the workspace directory as claude user
# The baseimage-gui will handle the GUI display
exec sudo -u claude code --new-window --wait "$WORKSPACE_DIR"
