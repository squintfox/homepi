#!/bin/bash

# TODO: i'm pretty sure this doesn't work

set -euo pipefail

STACK_NAME="homepi-command"
SERVICE_NAME="${STACK_NAME}_registry"
DATA_VOLUME="local_data_path"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/$STACK_NAME/registry-config.yml"
ORIGINAL_REPLICAS="1"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Registry config not found: $CONFIG_FILE" >&2
  exit 1
fi

restore_service() {
  if docker service inspect "$SERVICE_NAME" >/dev/null 2>&1; then
    docker service scale "$SERVICE_NAME=$ORIGINAL_REPLICAS"
  fi
}

if docker service inspect "$SERVICE_NAME" >/dev/null 2>&1; then
  ORIGINAL_REPLICAS="$(docker service inspect "$SERVICE_NAME" --format '{{if .Spec.Mode.Replicated}}{{.Spec.Mode.Replicated.Replicas}}{{else}}1{{end}}')"
  trap restore_service EXIT

  echo "Scaling $SERVICE_NAME to 0 for safe garbage collection..."
  docker service scale "$SERVICE_NAME=0"

  echo "Waiting for registry tasks to stop..."
  while docker ps -q --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" | grep -q .; do
    sleep 1
  done
fi

echo "Running Docker Registry garbage collection..."
docker run --rm \
  -v "$DATA_VOLUME:/local-data" \
  -v "$CONFIG_FILE:/etc/distribution/config.yml:ro" \
  registry:2 garbage-collect /etc/distribution/config.yml

echo "Garbage collection finished."

if [[ "$ORIGINAL_REPLICAS" != "0" ]]; then
  restore_service
  trap - EXIT
fi
