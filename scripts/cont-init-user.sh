#!/bin/sh
# Fix the app user (UID 1000) created by baseimage-gui at runtime.
# baseimage-gui sets shell=/sbin/nologin and home=/dev/null, which
# prevents VSCode from opening terminals.
usermod -s /bin/bash app
usermod -d /home/user app
