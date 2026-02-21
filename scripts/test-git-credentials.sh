#!/bin/bash
# Test script to verify git credentials configuration

set -e

echo "=== Git Credentials Test ==="

# Check git configuration
echo "1. Git user configuration:"
git config --global user.name || echo "  ❌ user.name not set"
git config --global user.email || echo "  ❌ user.email not set"

echo ""
echo "2. Git credential helper:"
git config --global credential.helper || echo "  ❌ credential.helper not set"

echo ""
echo "3. Credentials file locations:"
CREDENTIALS_FILE="/config/userdata/.git-credentials"
if [ -f "$CREDENTIALS_FILE" ]; then
    echo "  ✓ $CREDENTIALS_FILE exists"
    echo "  Permissions: $(stat -c %a $CREDENTIALS_FILE)"
    echo "  Lines in file: $(wc -l < $CREDENTIALS_FILE)"
else
    echo "  ❌ $CREDENTIALS_FILE does not exist"
fi

if [ -f "$HOME/.git-credentials" ]; then
    if [ -L "$HOME/.git-credentials" ]; then
        echo "  ✓ $HOME/.git-credentials is a symlink to $(readlink -f $HOME/.git-credentials)"
    else
        echo "  ✓ $HOME/.git-credentials exists (not a symlink)"
    fi
else
    echo "  ❌ $HOME/.git-credentials does not exist"
fi

echo ""
echo "4. Environment check:"
echo "  HOME=$HOME"
echo "  GITHUB_TOKEN=${GITHUB_TOKEN:+[SET]}"
echo "  GIT_USER_NAME=${GIT_USER_NAME:-[NOT SET]}"
echo "  GIT_USER_EMAIL=${GIT_USER_EMAIL:-[NOT SET]}"

echo ""
echo "=== Test Complete ==="