#!/bin/bash

set -euo pipefail

STACK_NAME="homepi-critical"
WEBPROXY_NETWORK_NAME="webproxy-backend"

# remove existing stack if present, then wait until services are gone
docker stack rm "$STACK_NAME" || true

for i in {1..60}; do
	SERVICES="$(docker stack services "$STACK_NAME" --format '{{.Name}}' 2>/dev/null || true)"
	if [[ -z "$SERVICES" ]]; then
		break
	fi
	echo "Waiting for stack $STACK_NAME to be removed..."
	sleep 1
done

echo "stack $STACK_NAME stopped"
