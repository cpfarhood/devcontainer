#!/bin/sh
# Start OpenSSH server when SSH=true.
# Runs as root during container initialisation (cont-init.d).
[ "${SSH:-false}" = "true" ] || exit 0

echo "=== SSH enabled: starting sshd ==="

HOME_DIR="/home/user"
HOST_KEY_STORE="$HOME_DIR/.ssh/host_keys"

# Persist host keys on the home PVC so clients don't see a "host key
# changed" warning after pod restarts.
if [ -d "$HOST_KEY_STORE" ] && [ -n "$(ls "$HOST_KEY_STORE"/ssh_host_* 2>/dev/null)" ]; then
    # Restore previously generated host keys
    echo "Restoring SSH host keys from PVC..."
    cp "$HOST_KEY_STORE"/ssh_host_* /etc/ssh/
    chmod 600 /etc/ssh/ssh_host_*_key
    chmod 644 /etc/ssh/ssh_host_*_key.pub
else
    # First boot: generate and save host keys to PVC
    echo "Generating SSH host keys (first boot)..."
    ssh-keygen -A 2>/dev/null || true
    mkdir -p "$HOST_KEY_STORE"
    cp /etc/ssh/ssh_host_* "$HOST_KEY_STORE/"
    chmod 700 "$HOST_KEY_STORE"
    chown -R 1000:1000 "$HOST_KEY_STORE"
    echo "SSH host keys saved to PVC."
fi

# Populate authorized_keys from env var (injected via Kubernetes secret)
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    mkdir -p "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"
    printf '%s\n' "$SSH_AUTHORIZED_KEYS" > "$HOME_DIR/.ssh/authorized_keys"
    chmod 600 "$HOME_DIR/.ssh/authorized_keys"
    chown -R 1000:1000 "$HOME_DIR/.ssh"
    echo "SSH authorized keys configured."
else
    echo "WARNING: SSH_AUTHORIZED_KEYS not set — you will not be able to log in."
fi

# Start sshd in background (root required to bind :22 and fork sessions)
/usr/sbin/sshd -D &

echo "sshd started (PID $!)"
