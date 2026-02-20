#!/bin/sh
# Start OpenSSH server for SSH IDE mode.
# Runs as root during container initialisation (cont-init.d).
[ "${IDE:-vscode}" = "ssh" ] || exit 0

echo "=== SSH IDE mode: starting sshd ==="

# Generate host keys if missing (first boot or ephemeral /etc/ssh)
ssh-keygen -A 2>/dev/null || true

# Populate authorized_keys from env var (injected via Kubernetes secret)
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    HOME_DIR="/home/user"
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
