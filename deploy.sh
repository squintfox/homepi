#!/bin/bash

set -euo pipefail

LOCAL_DATA_PATH="/opt/homepi/local-data"
REPO_PATH="$(pwd)"
HOMEPI_STACKS_PATH="/opt/homepi/homepi-stacks"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--local-data-path)
			if [[ $# -lt 2 ]]; then
				echo "Missing value for --local-data-path" >&2
				exit 1
			fi
			LOCAL_DATA_PATH="$2"
			shift 2
			;;
		--stacks-path)
			if [[ $# -lt 2 ]]; then
				echo "Missing value for --stacks-path" >&2
				exit 1
			fi
			HOMEPI_STACKS_PATH="$2"
			shift 2
			;;
		-h|--help)
			echo "Usage: $0 [--local-data-path <path>] [--stacks-path <path>]"
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			echo "Usage: $0 [--local-data-path <path>] [--stacks-path <path>]" >&2
			exit 1
			;;
	esac
done

mkdir -p "$LOCAL_DATA_PATH"
mkdir -p "$HOMEPI_STACKS_PATH"

# intentionally non-recursive to avoid accidentally changing permissions on the whole
# repo if the path is set incorrectly
chmod 755 "$LOCAL_DATA_PATH"
chmod 755 "$HOMEPI_STACKS_PATH"
chmod 755 "$REPO_PATH"

# Create docker volumes for local data, repo, and stacks
docker volume create --driver local --opt type=none --opt o=bind \
	--opt device="$LOCAL_DATA_PATH" local_data_path >/dev/null
docker volume create --driver local --opt type=none --opt o=bind \
	--opt device="$REPO_PATH" homepi_repo >/dev/null
docker volume create --driver local --opt type=none --opt o=bind \
	--opt device="$HOMEPI_STACKS_PATH" homepi_stacks >/dev/null

# Initialize Docker Swarm if not already initialized, required for secrets and swarm mode services
if [[ "$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]]; then
	echo "Initializing Docker Swarm..."
	docker swarm init >/dev/null
fi

# limit task history to prevent swarm from getting bogged down with old tasks if there are recurring failures
docker swarm update --task-history-limit 3

if ! docker secret inspect hpi_desec_token >/dev/null 2>&1; then
	read -r -s -p "Enter value for hpi_desec_token: " HPI_DESEC_TOKEN
	echo
	if [[ -z "$HPI_DESEC_TOKEN" ]]; then
		echo "hpi_desec_token cannot be empty." >&2
		exit 1
	fi
	printf '%s' "$HPI_DESEC_TOKEN" | docker secret create hpi_desec_token -
	unset HPI_DESEC_TOKEN
fi

# set to dummy secret value for now, will need to set correctly later
if ! docker secret inspect hpi_vault_token >/dev/null 2>&1; then
	printf '%s' 'CHANGE_ME' | docker secret create hpi_vault_token -
fi
if ! docker secret inspect hpi_portainer_token >/dev/null 2>&1; then
	printf '%s' 'CHANGE_ME' | docker secret create hpi_portainer_token -
fi

# Enable cgroup memory settings for docker monitoring

sudo grep -q "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1" /boot/firmware/cmdline.txt \
  || sudo sed -i 's/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt

# Raspberry Pi Auto Updates

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
