#!/bin/bash
# deploy_config.sh - regenerate swarm config and redeploy stack
# usage: ./deploy_config.sh <config-db-path> [stack-name]

set -euo pipefail

# require config database path as first argument
if [ -z "${1:-}" ]; then
    echo "usage: $0 <config-db-path> [stack-name]" >&2
    exit 1
fi
CONFIG_DB="$1"
STACK_NAME=${2:-hpi_containers}

# remove existing stack if present (will be redeployed later)
docker stack rm "$STACK_NAME" || true

# remove existing config if present
if docker config inspect hpi_config >/dev/null 2>&1; then
    echo "removing old config hpi_config"
    docker config rm hpi_config
else
    echo "no existing hpi_config config to remove"
fi

# generate new configuration
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

uv run ./homepi/convert_config.py "$CONFIG_DB" > "$TMPFILE"

docker config create hpi_config "$TMPFILE"

echo "config hpi_config updated"

# redeploy the stack
# you may need to adjust the compose file path if different

docker stack deploy -c "$STACK_NAME"/docker-compose.yml "$STACK_NAME"

echo "stack $STACK_NAME redeployed"