#!/bin/bash

set -euo pipefail

SECRET_NAME=""
STACK_NAME="homepi-command"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--secret)
			if [[ $# -lt 2 ]]; then
				echo "Missing value for --secret" >&2
				exit 1
			fi
			SECRET_NAME="$2"
			shift 2
			;;
		-h|--help)
			echo "Usage: $0 --secret <secret-name>"
			echo ""
			echo "Known secrets: hpi_vault_token, hpi_portainer_token, hpi_desec_token"
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			echo "Usage: $0 --secret <secret-name>" >&2
			exit 1
			;;
	esac
done

if [[ -z "$SECRET_NAME" ]]; then
	echo "Error: --secret <secret-name> is required" >&2
	echo "Usage: $0 --secret <secret-name>" >&2
	echo ""
	echo "Known secrets: hpi_vault_token, hpi_portainer_token, hpi_desec_token" >&2
	exit 1
fi

# stop the stack and wait for services to be gone
echo "Stopping stack $STACK_NAME..."
docker stack rm "$STACK_NAME" || true

for i in {1..60}; do
	SERVICES="$(docker stack services "$STACK_NAME" --format '{{.Name}}' 2>/dev/null || true)"
	if [[ -z "$SERVICES" ]]; then
		break
	fi
	echo "Waiting for stack $STACK_NAME to be removed..."
	sleep 1
done

# remove the existing secret
echo "Removing secret $SECRET_NAME..."
docker secret rm "$SECRET_NAME"

# prompt for new secret value
echo -n "Enter new value for $SECRET_NAME: "
read -rs SECRET_VALUE
echo ""

if [[ -z "$SECRET_VALUE" ]]; then
	echo "Error: secret value cannot be empty" >&2
	exit 1
fi

# create the new secret
printf '%s' "$SECRET_VALUE" | docker secret create "$SECRET_NAME" -
unset SECRET_VALUE

echo "Secret $SECRET_NAME recreated."

# redeploy the stack
./deploy_command.sh --no-build
