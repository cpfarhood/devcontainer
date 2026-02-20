#!/bin/sh
# Initialize persistent home directory structure for the app user
# This ensures Chrome settings and SSH keys persist across pod restarts

echo "=== Initializing persistent home directory ==="

# Ensure the user home directory exists with proper ownership
if [ ! -d "/home/user" ]; then
    echo "Creating /home/user directory..."
    mkdir -p /home/user
    chown app:app /home/user
fi

# Ensure critical directories exist for persistent data
echo "Ensuring persistent directories exist..."
mkdir -p /home/user/.config
mkdir -p /home/user/.ssh
mkdir -p /home/user/.cache

# Set proper ownership for all directories
chown -R app:app /home/user

# Ensure SSH directory has proper permissions
chmod 700 /home/user/.ssh

echo "Home directory initialization complete"