#!/bin/sh
set -e

# Add repo to git safe directories to avoid ownership issues
git config --global --add safe.directory /var/opt/homepi || true

# If the upgrade script exists, run it. Otherwise sleep to keep container alive briefly.
if [ -x /var/opt/homepi/upgrade.sh ]; then
  exec sh /var/opt/homepi/upgrade.sh
elif [ -f /var/opt/homepi/upgrade.sh ]; then
  exec sh /var/opt/homepi/upgrade.sh
else
  echo "/var/opt/homepi/upgrade.sh not found; sleeping"
  sleep 3600
fi
