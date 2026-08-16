#!/bin/bash

set -euo pipefail

STACK_NAME="homepi-command"

# Load stack-level environment variables
ENV_FILE="$STACK_NAME/.env"
if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
fi

git -C /stacks/ pull && git pull
uv pip install --upgrade \
	"configtool @ git+https://git.${HPI_DNS_DOMAIN}:${HPI_HTTPS_PORT}/squintfox/configtool.git" \
	"configtool-client @ git+https://git.${HPI_DNS_DOMAIN}:${HPI_HTTPS_PORT}/squintfox/configtool.git#subdirectory=configtool-client" \
	"configtool-secrets @ git+https://git.${HPI_DNS_DOMAIN}:${HPI_HTTPS_PORT}/squintfox/configtool.git#subdirectory=configtool-secrets"
uv run homepi/load.py
