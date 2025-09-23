# HomePi

## Notes

- You can set env var GIT_BRANCH in override for container homepi-updater, if you want to work on another branch.
- To do it locally: `GIT_BRANCH=dev ./upgrade.sh`

## Pre

- Create a desec account
- Register a domain
- Change nameservers to desec
- Create a GitHub account

## Raspberry Pi OS Lite

- With kb/mouse/monitor
  - set username/password
  - join wifi
  - set static IP
- Preferences >
  - hostname
  - ssh
  - reboot

## Raspberry Pi SSH

- Run:

    ```bash
    sudo apt update && \
    sudo apt install -y git && \
    sudo apt upgrade -y && \
    curl -fsSL https://get.docker.com | sh && \
    sudo usermod -aG docker $USER && \
    echo "✅ Docker + Compose installed."
- Run:

    ```bash
    sudo apt update && \
    sudo apt full-upgrade -y && \
    echo "✅ Pi updates complete, rebooting."
    sudo reboot
    ```bash

- Run:

    ```bash
    sudo rpi-eeprom-update -a && \
    echo "✅ Pi EEPROM updates complete, rebooting."
    sudo reboot
    ```

- Run:

    ```bash
    cd /var/opt
    sudo git clone https://github.com/squintfox/homepi.git
    sudo chown -R homepi:homepi /var/opt/homepi
    cd /var/opt/homepi
    echo "✅ Repo cloned from git."
    ```

- run `./first_time.sh`
- run `./gmail_setup.sh`
  - See below
- run `./upgrade.sh`
- run `./start.sh`
  - wait for caddy to issue all the certs

## email (Gmail)

- Create a Gmail App Password
  - Because Gmail blocks “less secure apps,” you must:
    - Enable 2‑Step Verification on your Google account.
    - Create an App Password for “Mail” → “Other” (name it e.g. homepi).
    - [GMail - Security](https://myaccount.google.com/intro/security)
      - 2‑Step Verification
      - App passwords
      - App name: homepi
  - Use this app password instead of your normal Gmail password.
- Run:

    ```bash
    cd /var/opt/homepi
    ./gmail_setup.sh
    ```

## dash (Jump)

Ready to run

## update (Watchtower)

Ready to run

## monitor (Beszel)

- Log in, set username/password
- Go to Add System
  - Name: homepi
  - Host/IP: /beszel_socket/beszel.sock
- Click Add
- Run: `./beszel_setup.sh`
- Run:

    ```bash
    cd /var/opt/homepi/monitor
    docker compose down && docker compose up -d
    ```

## dns (Technitium)

- Log in as "admin/admin", set username/password
- Zones >
  - Add Zone > [yourdomain.com]
    - Primary
  - Add Record
    - Name: *
    - IPv4 Address: [your static ip]
- Apps > App Store
  - Query Logs (Sqlite) > Install

## manage (Portainer)

- Run:  (Portainer has a 5-minutes-from-boot timer for setup)

    ```bash
    cd /var/opt/homepi/manage
    docker compose restart
    ```

- Log in, set username/password

## assets (Snipe-IT)

- Run:

    ```bash
    cd /var/opt/homepi/assets
    sudo chown -R 10000:homepi /var/opt/homepi/assets/app_storage/
    docker compose restart
    ```

- Go to site >
  - Create Database Tables
  - Create User
    - Name: HomePi Assets
    - Check "Generate auto-incrementing asset tags"
    - Email Domain: [yourdomain.com]
- Import
  - Import each csv file as their notated type.

## automate (Home Assistant)

- Run:

    ```bash
    cd /var/opt/homepi
    ./homeassistant_setup.sh
    cd /var/opt/homepi/automate
    docker compose restart
    ```

- Go to site >
  - Create my smart home
  - set username/password
  - Address
- Run:  (THIS REQUIRES A GITHUB ACCOUNT)

    ```bash
    cd /var/opt/homepi/automate
    docker compose exec -it homeassistant bash
    ```

- Run:  (inside container)

    ```bash
    wget -O - https://get.hacs.xyz | bash -
    ```

- Exit, then run:

    ```bash
    docker compose restart
    ```

- Go to site >
  - Settings > Devices & Services > Add Integration
    - HACS
    - Authenitcate to GitHub

## backup (backrest/Restic/rclone)

- From: <https://rclone.org/drive/#making-your-own-client-id>
  - <https://console.developers.google.com/>
  - Project: homepi
  - - enable
  - Google Drive API > Enable
  - Credentials > left-side
  - Configure consent screen
    - App: homepi
    - Email
    - External
    - Email
  - Data Access > left
  - Add scopes > Manually
    - Paste: <https://www.googleapis.com/auth/docs,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/drive.metadata.readonly>
  - Audience > Test Users
    - Add your Email
  - Back to credentials > create credentials > ouath client id
    - Desktop app
    - Name: homepi
    - oauth consent screen
      - Audience > Public App

- rclone config

  - ```bash
    cd /var/opt/homepi/backup
    docker compose exec backrest rclone config
    ```

    - Name: google_drive
    - 20 (google drive)
    - client id
    - key
    - 1 (full)
    - blank (service_account_file)
    - N (advanced)
    - N (web browser)
    - Download to Windows:
      - <https://rclone.org/downloads/>
      - run rclone here
    - paste
    - N (shared)
    - Y (save)
    - Q (quit)

- backrest gui
  - instance_id: homepi
  - enable auth, set admin password
  - add a repo (see default-config.json on local machine)
    - SAVE YOUR KEY!!!!!
  - add a plan
