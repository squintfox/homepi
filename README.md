# HomePi

A self-hosted home server stack running on a Raspberry Pi with Docker Swarm and Portainer.

## Prerequisites

Before starting, make sure you have:

- A [deSEC](https://desec.io) account with a registered domain and nameservers pointing to deSEC
- A [GitHub](https://github.com) account (for Home Assistant)
- A Gmail account

## 1. Raspberry Pi OS Lite (Initial Setup)

With a keyboard, mouse, and monitor connected:

1. Set username and password.
2. Join Wi-Fi.
3. Set a static IP.
4. Open Preferences and configure:
   - Hostname
   - SSH (enable)
5. Reboot.

## 2. First-Time SSH Setup

SSH into the Pi and run each block in order.

### Install Git and Docker

```bash
sudo apt update && \
sudo apt install -y git && \
sudo apt upgrade -y && \
curl -fsSL https://get.docker.com | sh && \
sudo usermod -aG docker $USER && \
echo "Docker and Compose installed."
```

### Full System Upgrade

```bash
sudo apt update && \
sudo apt full-upgrade -y && \
echo "Pi updates complete, rebooting." && \
sudo reboot
```

### EEPROM Update

```bash
sudo rpi-eeprom-update -a && \
echo "Pi EEPROM updates complete, rebooting." && \
sudo reboot
```

### Clone the Repos

```bash
sudo mkdir -p /opt/homepi
sudo mkdir -p /opt/homepi/local-data
cd /opt/homepi
sudo git clone https://github.com/squintfox/homepi.git
sudo git clone https://github.com/squintfox/homepi-stacks.git
sudo chown -R homepi:homepi /opt/homepi
echo "Repos cloned."
```

### Optional: Change Password and Set Static IP

```bash
# Change user password
passwd

# Set static IP via NetworkManager TUI
sudo nmtui
sudo systemctl restart NetworkManager
```

### Start HomePi

```bash
./deploy.sh
cp configtool_db.user.slim.yml configtool_db.user.yml

# Make your updates
nano configtool_db.user.yml

# Allows image build before the local registry is loaded
./deploy_command.sh --local
./exec_shell.sh

# From inside the container (it is expected to fail on individual stacks)
./run.sh
exit

./deploy_critical.sh
```

After this, wait while Let's Encrypt issues certificates. This can take several minutes.
Use `./monitor_critical.sh` to validate progress.

```bash
# When finished, force a service restart so you can log into Portainer within 5 minutes of start
./deploy_critical.sh --no-build --force
```

## Post-Bootstrap Setup

At this point Technitium should be running. You can set your local PC to use the HomePi IP as its DNS server for configuration, but you still need your home network to forward DNS queries to HomePi.

### DNS (Technitium)

Log into <https://dns.[YOUR_DOMAIN]> and change the admin password.

- Default: `admin/admin`
- Apps -> App Store
  - Install `Query Logs (Sqlite)`

### Management (Portainer)

Log into <https://manage.[YOUR_DOMAIN]> and set an admin password.

- Add Environment -> Docker Swarm
  - Name: `local-swarm`
  - Type: `Agent`
  - URL: `portainer-agent:9001`
- Go to top-right user menu -> My Account
  - Add access token (store this value)

### Secrets (Vaultwarden)

Log into <https://vault.[YOUR_DOMAIN]> and set an admin password.

- Create account using your primary email address
- Choose a strong master password (store this value)

```bash
# Use the access token from Portainer
./update_docker_secret.sh --secret hpi_portainer_token
# Use the master password from Vaultwarden
./update_docker_secret.sh --secret hpi_vault_token
```

### Seed Vaultwarden Secrets

Create these items in Vaultwarden:

- Folder: `homepi`
- Secret: `hpi_code_server`
  - Folder: `homepi`
  - Username: [blank]
  - Password: use the password generator (this is your VS Code login password)
- Secret: `hpi_beszel_agent`
  - Folder: `homepi`
  - Username: [blank]
  - Password: `12345` (temporary)
- Secret: `hpi_speedtest_app_key`
  - Folder: `homepi`
  - Username: [blank]
  - Password: use `echo "$(openssl rand -base64 32)"` on the HomePi CLI to generate
- Secret: `hpi_speedtest_db`
  - Folder: `homepi`
  - Username: `speedtest`
  - Password: use the password generator (this is your Postgres password)

Then add `replicas=1` to the `homepi-command_run` service. This runs deployment of the stacks.  Once stacks are loaded and Caddy has issued all certificates, proceed.

### Monitoring (Beszel)

Log into <https://monitoring.[YOUR_DOMAIN]> and set an admin password.

- Create account using your primary email address
- After login, Add System
  - Docker
    - Name: `homepi`
    - Host/IP: `/beszel_socket/beszel.sock`
  - Record the Public Key value
- Update Vaultwarden secret `hpi_beszel_agent` with that Public Key value
- In Portainer, go to Stacks -> `monitor`
  - This is a temporary step because Portainer env vars cannot be overwritten without forcing a TF change
  - Environment Variables
    - `BESZEL_AGENT_PASSWORD`: previous Public Key value
- Save Settings
- Pull and Redeploy

### Speedtest Tracker

Log into <https://speedtest.[YOUR_DOMAIN]> and set up an admin account.

- Default: `admin@example.com/password`
- Log in -> top-right profile
- Update email and password

# TODO:

- select a stack loading
- email
- backups
- smb (no pw, all mount)
- plex (no requirements)
- how to update command/critical?
- how do you get full updates, with potainer doing a stack pull?
- !! you don't need a critical stack anymore, you can build in a container and upload to registry
  - well you probably still do, portainer, registry and caddy
  - but you can build command in a container now and update without SSH
  - same with caddy
- can you encrypt tfstate??



## Recommended Stacks

### update

Create in Vaultwarden a new secret named `hpi_shepherd_registry`:

- This requires personal Docker Hub credentials. Accounts are free: <https://hub.docker.com>
- Folder: `homepi`
- Username: [Docker Hub username]
- Password: [Docker Hub password]

### email (Gmail)

Gmail blocks less secure apps, so use an App Password:

1. Go to [Google Account Security](https://myaccount.google.com/intro/security).
2. Enable 2-Step Verification.
3. Create an App Password -> Mail -> Other -> name it `homepi`.
4. Use that app password (not your normal Gmail password) in the setup script.

```bash
cd /var/opt/homepi
./gmail_setup.sh
```

### assets (Snipe-IT)

```bash
cd /var/opt/homepi/assets
sudo chown -R 10000:homepi /var/opt/homepi/assets/app_storage/
docker compose restart
```

Then in the site UI:

1. Create Database Tables.
2. Create User:
   - Name: `HomePi Assets`
   - Check Generate auto-incrementing asset tags
   - Email domain: `[yourdomain.com]`
3. Import each CSV file as its noted type.

### automate (Home Assistant)

```bash
cd /var/opt/homepi
./homeassistant_setup.sh

cd /var/opt/homepi/automate
docker compose restart
```

Then in the site UI:

1. Create my smart home and set username, password, and address.

#### Install HACS (requires GitHub account)

```bash
cd /var/opt/homepi/automate
docker compose exec -it homeassistant bash
```

Inside the container:

```bash
wget -O - https://get.hacs.xyz | bash -
```

Exit the container, then restart:

```bash
docker compose restart
```

Back in the UI: Settings -> Devices and Services -> Add Integration -> HACS -> authenticate with GitHub.

### backup (backrest / Restic / rclone)

#### 1. Create a Google Drive OAuth Client

Follow <https://rclone.org/drive/#making-your-own-client-id>:

1. Go to <https://console.developers.google.com/>.
2. Create a project named `homepi`.
3. Enable the Google Drive API.
4. Go to Credentials -> Configure consent screen:
   - App name: `homepi`
   - User type: `External`
   - Add your email under Test Users
5. Under Data Access -> Add scopes, paste:

   ```text
   https://www.googleapis.com/auth/docs,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/drive.metadata.readonly
   ```

6. Go back to Credentials -> Create Credentials -> OAuth client ID:
   - Type: `Desktop app`
   - Name: `homepi`

#### 2. Configure rclone

```bash
cd /var/opt/homepi/backup
docker compose exec backrest rclone config
```

When prompted:

| Prompt | Value |
| --- | --- |
| Name | `google_drive` |
| Storage type | `20` (Google Drive) |
| Client ID | your client ID |
| Client Secret | your key |
| Scope | `1` (full access) |
| Service account file | blank |
| Advanced config | `N` |
| Web browser auth | `N` (download rclone for Windows from <https://rclone.org/downloads/>, run locally, then paste token) |
| Shared drive | `N` |
| Save | `Y` |
| Quit | `Q` |

#### 3. Configure backrest

1. Set `instance_id` to `homepi`.
2. Enable auth and set an admin password.
3. Add a repo (refer to `default-config.json` on your local machine).
   - Save your encryption key. It cannot be recovered.
4. Add a plan.
