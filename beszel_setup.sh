#!/bin/bash

# Usage: ./beszel_setup.sh [ssh public key] [token]
SSH_PUBLIC_KEY="$1"

if [ -z "$SSH_PUBLIC_KEY" ]; then
  echo "Usage: $0 \"[ssh public key]\" [token]"
  exit 1
fi

for dir in */ ; do
  TARGET_FILE="${dir}docker-compose.override.yml"

  if [ -f "$TARGET_FILE" ]; then
    sed -i "s|<beszel_ssh_key>|$SSH_PUBLIC_KEY|g" "$TARGET_FILE"
    echo "✅ Processed $TARGET_FILE"
  fi
done
