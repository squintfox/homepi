#!/bin/bash

# Usage: ./gmail_setup.sh [your gmail address] [your gmail app password]
EMAIL="$1"
PASSWORD="$2"

if [ -z "$EMAIL" ]; then
  echo "Usage: $0 [your gmail address] [your gmail app password] (no spaces)"
  exit 1
fi
if [ -z "$PASSWORD" ]; then
  echo "Usage: $0 [your gmail address] [your gmail app password (no spaces)]"
  exit 1
fi

for dir in */ ; do
  for file in "docker-compose.override.yml" "default-config.json"; do
    TARGET_FILE="${dir}${file}"
    if [ -f "$TARGET_FILE" ]; then
      sed -i "s|<gmail_address>|$EMAIL|g" "$TARGET_FILE"
      sed -i "s|<gmail_app_pass>|$PASSWORD|g" "$TARGET_FILE"
      echo "✅ Processed $TARGET_FILE"
    fi
  done
done