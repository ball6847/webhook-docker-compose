#!/bin/sh

set -e

cd /app

if [ -f "$WEBHOOK_MATCH_TOKEN_FILE" ];
then
    WEBHOOK_MATCH_TOKEN=`cat $WEBHOOK_MATCH_TOKEN_FILE`
else
    WEBHOOK_MATCH_TOKEN=${WEBHOOK_MATCH_TOKEN:-123456789}
fi

jq ".[0][\"trigger-rule\"].match.value = \"${WEBHOOK_MATCH_TOKEN}\"" hooks.json | sponge hooks.json

exec /usr/local/bin/webhook -verbose -hooks=/app/hooks.json -hotreload "$@"
