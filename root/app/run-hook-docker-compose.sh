#!/bin/sh

set -e

SERVICE=$1
VERSION=$2
GIT_CLONE_DIR=git
VAR_FILE="${VAR_FILE:-vars.json}"
TEMPLATE_FILE="${TEMPLATE_FILE:-template.yml}"

export DOCKER_COMPOSE_PROJECT="${DOCKER_COMPOSE_PROJECT:-app}"
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

if [ -z "$GIT_PRIVATE_KEY_FILE" ] || [ ! -f "$GIT_PRIVATE_KEY_FILE" ];
then
    echo "No GIT_PRIVATE_KEY_FILE found, stopping"
    exit 1;
fi

if [ -z "$GIT_CLONE_URL" ];
then
    echo "No GIT_CLONE_URL found, stopping"
    exit 1;
fi

# import ssh key
mkdir -p $HOME/.ssh
cp -f "$GIT_PRIVATE_KEY_FILE" "$HOME/.ssh/id_rsa"
chmod 600 $HOME/.ssh/id_rsa

# TODO: how to handle queue ? as we don't want to let it run simultaneously

# clone or pull
if [ ! -d "$GIT_CLONE_DIR" ];
then
    echo "Cloning repository"
    git clone "$GIT_CLONE_URL" "$GIT_CLONE_DIR"
    cd $GIT_CLONE_DIR
else
    echo "Updating working tree from remote"
    cd $GIT_CLONE_DIR
    # make sure it's clean before doing git pull
    git clean -fd
    git checkout .
    git pull origin master
fi

# is entering deeper directory needed ?
if [ ! -z "$GIT_PROJECT_PATH" ];
then
    echo "Entering $GIT_PROJECT_PATH"
    cd "$GIT_PROJECT_PATH"
fi

if [ ! -f "$TEMPLATE_FILE" ] || [ ! -f "$VAR_FILE" ];
then
    echo "TEMPLATE_FILE or VAR_FILE is missing"
    exit 1;
fi

# login digitaloceans container registry if necessary
if [ -f "$DIGITALOCEAN_TOKEN_FILE" ];
then
    DIGITALOCEAN_TOKEN=`cat $DIGITALOCEAN_TOKEN_FILE`
fi

if [ ! -z "$DIGITALOCEAN_TOKEN" ];
then
    echo "Logging in to digitalocean container registry"
    DIGITALOCEAN_TOKEN_EXPIRY=${DIGITALOCEAN_TOKEN_EXPIRY:-300}
    doctl registry login --access-token "$DIGITALOCEAN_TOKEN" --expiry-seconds $DIGITALOCEAN_TOKEN_EXPIRY
fi

if [ ! -z "$SERVICE" ] && [ ! -z "$VERSION" ];
then
    echo "Updating variable file"
    jq ".[\"${SERVICE}\"] = \"${VERSION}\"" "$VAR_FILE" | sponge "$VAR_FILE"
fi

echo "Applying docker-compose changes"
emrichen -f "$VAR_FILE" "$TEMPLATE_FILE" | docker-compose -f - up -d

if [ ! -z "$(git status --porcelain)" ];
then
    echo "Commiting changes"
    git commit -am "updated from CI server `date +"%F %r"`"
    git push origin master
else
    echo "Working tree is clean, nothing to commit"
fi

echo "Done"
