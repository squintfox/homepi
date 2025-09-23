#!/bin/sh
set -e

# Add repo to git safe directories to avoid ownership issues
git config --global --add safe.directory /var/opt/homepi || true

sh /var/opt/homepi/stop-services.sh && exec sh /var/opt/homepi/start-services.sh
