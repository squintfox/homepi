#!/bin/bash

grep -q "trusted_proxies:" /var/opt/homepi/automate/config/configuration.yaml || \
sudo tee -a /var/opt/homepi/automate/config/configuration.yaml > /dev/null <<'EOF'
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12
EOF
