#!/bin/sh
set -e

# Add repo to git safe directories to avoid ownership issues
git config --global --add safe.directory /var/homepi || true

# If the upgrade script exists, run it. Otherwise sleep to keep container alive briefly.
if [ -x /var/homepi/upgrade.sh ]; then
  exec sh /var/homepi/upgrade.sh
elif [ -f /var/homepi/upgrade.sh ]; then
  exec sh /var/homepi/upgrade.sh
else
  echo "/var/homepi/upgrade.sh not found; sleeping"
  sleep 3600
fi
