#!/bin/bash
# deploy.sh — Deploy AdGuard Home from MacBook Pro to MacBook Air

set -e

# ---- Configuration ----
if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
else
    echo "Error: .env file not found. Please create one based on the README."
    exit 1
fi

REMOTE_DIR="/Users/$REMOTE_USER/adguard"

SSH_OPTS="-o ControlMaster=auto -o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlPersist=10m"

echo "Deploying AdGuard Home to $REMOTE_USER@$REMOTE_HOST..."

ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

scp $SSH_OPTS docker-compose.yml "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/docker-compose.yml"
echo "docker-compose.yml copied successfully."

ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    export PATH=\"/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:\$PATH\"
    DOCKER_BIN=\$(command -v docker || true)
    if [ -z \"\$DOCKER_BIN\" ]; then
        echo 'Docker is not installed on the remote host.'
        exit 1
    fi

    # Isolate Docker config + HOME to avoid macOS Keychain helper
    TMP_HOME=\$(mktemp -d)
    export HOME=\"\$TMP_HOME\"
    export DOCKER_CONFIG=\"\$HOME/.docker\"
    mkdir -p \"\$DOCKER_CONFIG\"
    echo '{}' > \"\$DOCKER_CONFIG/config.json\"

    # Pre-pull image using isolated config
    \"\$DOCKER_BIN\" --config \"\$DOCKER_CONFIG\" pull adguard/adguardhome:latest

    if \"\$DOCKER_BIN\" compose version >/dev/null 2>&1; then
        cd $REMOTE_DIR && \"\$DOCKER_BIN\" --config \"\$DOCKER_CONFIG\" compose up -d
    elif command -v docker-compose >/dev/null 2>&1; then
        cd $REMOTE_DIR && DOCKER_CONFIG=\"\$DOCKER_CONFIG\" docker-compose up -d
    else
        echo 'Docker Compose is not available on the remote host.'
        exit 1
    fi
"

echo "AdGuard Home is running on $REMOTE_HOST"
echo "Setup wizard: http://$REMOTE_HOST:3000"
echo "Dashboard:    http://$REMOTE_HOST:80"