#!/bin/sh
set -e

# Add repo to git safe directories to avoid ownership issues
git config --global --add safe.directory /var/homepi || true

sh /var/homepi/stop-services.sh && exec sh /var/homepi/start-services.sh
