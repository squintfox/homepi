#!/bin/bash

# Usage: ./first_time.sh [yourdomain.com] [your@email.com] [desec_token]
DOMAIN="$1"
DESEC_TOKEN="$2"
SNIPE_APP_KEY=$(openssl rand -base64 32)

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 [yourdomain.com] [desec_token]"
  exit 1
fi
if [ -z "$DESEC_TOKEN" ]; then
  echo "Usage: $0 [yourdomain.com] [desec_token]"
  exit 1
fi

echo "Existing docker-compose.override.yml will not be overwritten, but you can delete them to re-run this setup."
sudo find . -type f -name 'docker-compose.override.yml'
# sudo find . -type f -name 'docker-compose.override.yml' -exec rm -v {} +

generate_random_string() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

#### Update sample files with user values ####

for dir in */ ; do
  for pair in "docker-compose.override.yml.sample:docker-compose.override.yml" "default-config.json.sample:default-config.json"; do
    SAMPLE_FILE="${dir}$(echo "$pair" | cut -d: -f1)"
    TARGET_FILE="${dir}$(echo "$pair" | cut -d: -f2)"

    if [ -f "$SAMPLE_FILE" ] && [ ! -f "$TARGET_FILE" ]; then
      cp "$SAMPLE_FILE" "$TARGET_FILE"
      sed -i "s|replacethisdomain.com|$DOMAIN|g" "$TARGET_FILE"
      sed -i "s|<desec_token>|$DESEC_TOKEN|g" "$TARGET_FILE"
      sed -i "s|<replace_random_a>|$(generate_random_string)|g" "$TARGET_FILE"
      sed -i "s|<replace_random_b>|$(generate_random_string)|g" "$TARGET_FILE"
      sed -i "s|<snipe_app_key>|$SNIPE_APP_KEY|g" "$TARGET_FILE"
      echo "✅ Processed $TARGET_FILE"
    fi
  done
done

#### Enable cgroup memory settings for docker monitoring ####

sudo grep -q "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" /boot/firmware/cmdline.txt \
  || sudo sed -i 's/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt

#### Raspberry Pi Updates ####

set -e

echo "🔧 Updating package lists..."
sudo apt update

echo "📦 Installing unattended-upgrades..."
sudo apt install -y unattended-upgrades

echo "✅ Enabling unattended-upgrades..."
sudo dpkg-reconfigure --priority=low unattended-upgrades

echo "📝 Configuring automatic reboot..."
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=\${distro_codename},label=Debian-Security";
        "origin=Raspbian,codename=\${distro_codename},label=Raspbian";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

echo "🕒 Setting periodic update schedule..."
sudo tee /etc/apt/apt.conf.d/10periodic > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "🧪 Running dry-run test..."
sudo unattended-upgrades --dry-run --debug

echo "✅ Automatic updates are now configured!"

#### Setup script to run container rebuild at boot ####

SERVICE_NAME=container-rebuild

# Write the systemd service unit
cat <<'EOF' | sudo tee /etc/systemd/system/container-rebuild.service > /dev/null
[Unit]
Description=Rebuild containers at boot
After=network.target docker.service

[Service]
Type=oneshot
WorkingDirectory=/var/opt/homepi
ExecStart=/var/opt/homepi/restart.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 3. Enable and start
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME.service
sudo systemctl start $SERVICE_NAME.service

echo "Service $SERVICE_NAME installed and enabled."

echo ""
echo "Please reboot before proceeding."
