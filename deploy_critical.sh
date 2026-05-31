#!/bin/bash

set -euo pipefail


STACK_NAME="homepi-critical"
WEBPROXY_NETWORK_NAME="webproxy-backend"
DO_BUILD=true
DO_DEPLOY=true
FORCE_UPGRADE=false

# Load stack-level environment variables used by compose interpolation.
ENV_FILE="$STACK_NAME/.env"
if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
fi

while [[ $# -gt 0 ]]; do
       case "$1" in
	       --no-build)
		       DO_BUILD=false
		       shift
		       ;;
	       --no-deploy)
		       DO_DEPLOY=false
		       shift
		       ;;
	       --force)
		       FORCE_UPGRADE=true
		       shift
		       ;;
	       -h|--help)
		       echo "Usage: $0 [--no-build] [--no-deploy] [--force]"
		       exit 0
		       ;;
	       *)
		       echo "Unknown argument: $1" >&2
		       echo "Usage: $0 [--no-build] [--no-deploy] [--force]" >&2
		       exit 1
		       ;;
       esac
done

# build stack image(s)
if [[ "$DO_BUILD" == "true" ]]; then
	docker compose -f "$STACK_NAME"/docker-compose.build.yml build --no-cache

	echo "Pushing docker image to local registry..."
	if ! docker compose -f "$STACK_NAME"/docker-compose.build.yml push; then
		 echo "Warning: docker push failed; continuing with deployment." >&2
	fi
else
	echo "Skipping build step (--no-build)"
fi

# Ensure shared external network exists before stack deploy.
if docker network inspect "$WEBPROXY_NETWORK_NAME" >/dev/null 2>&1; then
	NETWORK_DRIVER="$(docker network inspect -f '{{.Driver}}' "$WEBPROXY_NETWORK_NAME")"
	NETWORK_SCOPE="$(docker network inspect -f '{{.Scope}}' "$WEBPROXY_NETWORK_NAME")"
	if [[ "$NETWORK_DRIVER" != "overlay" || "$NETWORK_SCOPE" != "swarm" ]]; then
		echo "Network '$WEBPROXY_NETWORK_NAME' exists but is '$NETWORK_DRIVER/$NETWORK_SCOPE'; expected 'overlay/swarm'." >&2
		echo "Remove or rename the conflicting network, then re-run deploy." >&2
		exit 1
	fi
else
	echo "Creating missing overlay network: $WEBPROXY_NETWORK_NAME"
	docker network create --driver overlay --attachable "$WEBPROXY_NETWORK_NAME" >/dev/null
fi

# redeploy the stack
if [[ "$DO_DEPLOY" == "true" ]]; then
	COMPOSE_FILES=(-c "$STACK_NAME"/docker-compose.yml)
	if [[ -f "$STACK_NAME"/docker-compose.override.yml ]]; then
		 COMPOSE_FILES+=(-c "$STACK_NAME"/docker-compose.override.yml)
	fi
	docker stack deploy --prune --resolve-image always "${COMPOSE_FILES[@]}" "$STACK_NAME"

	if [[ "$FORCE_UPGRADE" == "true" ]]; then
		 echo "Stack $STACK_NAME redeployed, forcing service updates..."
		 docker stack services "$STACK_NAME" --format '{{.Name}}' | xargs -r -n1 docker service update --force
		 echo "Services in stack $STACK_NAME restarted."
	else
		 echo "Stack $STACK_NAME redeployed. Skipping forced service restart (use --force to enable)."
	fi
else
	echo "Skipping deploy step (--no-deploy)"
fi
