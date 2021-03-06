#!/bin/bash

SSH_PRIVATE_KEY=$1
DOKKU_USER=$2
DOKKU_HOST=$3
DOKKU_APP_NAME=$4
DOKKU_REMOTE_BRANCH=$5
GIT_PUSH_FLAGS=$6
DOKKU_APP_PORT=$7
DOKKU_ENABLE_SSL=$8

# Setup the SSH environment
echo "[###] Setup the SSH environment..."
mkdir -p ~/.ssh
eval `ssh-agent -s`
ssh-add - <<< "$SSH_PRIVATE_KEY"
ssh-keyscan $DOKKU_HOST >> ~/.ssh/known_hosts

# Setup the git environment
echo "[###] Setup the git environment"
git_repo="$DOKKU_USER@$DOKKU_HOST:$DOKKU_APP_NAME"
cd "$GITHUB_WORKSPACE"
git remote add deploy "$git_repo"

SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
DOKKU="$SSH $DOKKU_USER@$DOKKU_HOST"

echo "[###] Removing previous app"
$DOKKU apps:destroy --force $DOKKU_APP_NAME

echo "[###] Creating app"
$DOKKU apps:create $DOKKU_APP_NAME

echo "[###] Setting proxy ports"
$DOKKU proxy:ports-set $DOKKU_APP_NAME $DOKKU_APP_PORT

echo "[###] Listing proxy ports"
$DOKKU proxy:ports $DOKKU_APP_NAME

# Prepare to push to Dokku git repository
REMOTE_REF="$GITHUB_SHA:refs/heads/$DOKKU_REMOTE_BRANCH"

GIT_COMMAND="git push deploy $REMOTE_REF $GIT_PUSH_FLAGS"
echo "GIT_COMMAND=$GIT_COMMAND"

# Push to Dokku git repository
GIT_SSH_COMMAND="$SSH $GIT_COMMAND"
