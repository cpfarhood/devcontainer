#!/bin/sh
# Fix the app user (UID 1000) created by baseimage-gui at runtime.
# baseimage-gui sets shell=/sbin/nologin and home=/dev/null, which
# prevents VSCode from opening terminals.
if id app >/dev/null 2>&1; then
    usermod -s /bin/bash app
    usermod -d /config/userdata app
else
    echo "WARNING: 'app' user not found, skipping usermod" >&2
fi
