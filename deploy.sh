#!/bin/bash
# deploy.sh — Deploy AdGuard Home from MacBook Pro to MacBook Air

# ---- Configuration ----
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo "Error: .env file not found. Please create one based on the README."
    exit 1
fi

REMOTE_DIR="/Users/$REMOTE_USER/adguard" 

echo "Deploying AdGuard Home to $REMOTE_USER@$REMOTE_HOST..."
ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR" # Create remote directory if it doesn't exist
scp docker-compose.yml "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/docker-compose.yml" # Copy docker-compose.yml to remote machine

if [ $? -ne 0 ]; then
    echo "Failed to copy docker-compose.yml"
    exit 1
fi

echo "docker-compose.yml copied successfully."

# SSH into the remote machine and start the container
ssh "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && docker compose up -d"

if [ $? -ne 0 ]; then
    echo "Failed to start AdGuard Home"
    exit 1
fi

echo "AdGuard Home is running on $REMOTE_HOST"
echo "Setup wizard: http://$REMOTE_HOST:3000"
echo "Dashboard:    http://$REMOTE_HOST:80"
