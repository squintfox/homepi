#!/bin/bash

BRANCH="${GIT_BRANCH:-main}"

if [ -z "$GIT_BRANCH" ]; then
  echo "GIT_BRANCH is not set. Defaulting to '$BRANCH'."
else
  echo "Using GIT_BRANCH='$BRANCH'."
fi

docker system prune -f
git fetch
git checkout "$BRANCH"
git pull 
docker compose -f web/docker-compose.yml build --no-cache
docker compose -f manage/docker-compose.yml pull
docker compose -f monitor/docker-compose.yml pull
docker compose -f dns/docker-compose.yml pull
docker compose -f smtp/docker-compose.yml pull
docker compose -f assets/docker-compose.yml pull
docker compose -f automate/docker-compose.yml pull
docker compose -f dash/docker-compose.yml pull
docker compose -f backup/docker-compose.yml pull
docker compose -f update/docker-compose.yml pull
docker compose -f update/docker-compose.yml build homepi-updater homepi-restart --no-cache
docker compose -f update/docker-compose.yml -f update/docker-compose.override.yml create homepi-restart

echo "Run ./restart.sh or reboot the host for changes to take effect"