#!/bin/bash

set -euo pipefail

DEFAULT_SERVICE_NAME="homepi-command_command"

print_usage() {
	echo "Usage: $0 [swarm-service-name] [shell]"
	echo
	echo "Defaults:"
	echo "  swarm-service-name: $DEFAULT_SERVICE_NAME"
	echo "  shell: bash"
	echo
	echo "Examples:"
	echo "  $0"
	echo "  $0 homepi-command_command"
	echo "  $0 homepi-critical_portainer sh"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	print_usage
	exit 0
fi

SERVICE_NAME="${1:-$DEFAULT_SERVICE_NAME}"
SHELL_BIN="${2:-bash}"

CONTAINER_ID="$(docker ps -q --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" | head -n 1)"

if [[ -z "$CONTAINER_ID" ]]; then
	echo "No running container found for service: $SERVICE_NAME" >&2
	echo "Check service tasks with: docker service ps $SERVICE_NAME" >&2
	exit 1
fi

echo "Opening $SHELL_BIN in container $CONTAINER_ID for service $SERVICE_NAME"
exec docker exec -it "$CONTAINER_ID" "$SHELL_BIN"