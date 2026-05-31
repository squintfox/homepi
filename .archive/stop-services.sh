#!/bin/bash

docker compose -f update/docker-compose.yml down watchtower
docker compose -f backup/docker-compose.yml down
docker compose -f dash/docker-compose.yml down
docker compose -f automate/docker-compose.yml down
docker compose -f assets/docker-compose.yml down
docker compose -f smtp/docker-compose.yml down
docker compose -f dns/docker-compose.yml down
docker compose -f monitor/docker-compose.yml down
