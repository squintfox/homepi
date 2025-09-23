#!/bin/bash

docker compose -f monitor/docker-compose.yml -f monitor/docker-compose.override.yml up -d
docker compose -f dns/docker-compose.yml -f dns/docker-compose.override.yml up -d
docker compose -f smtp/docker-compose.yml -f smtp/docker-compose.override.yml up -d
docker compose -f assets/docker-compose.yml -f assets/docker-compose.override.yml up -d
docker compose -f automate/docker-compose.yml -f automate/docker-compose.override.yml up -d
docker compose -f dash/docker-compose.yml -f dash/docker-compose.override.yml up -d
docker compose -f backup/docker-compose.yml -f backup/docker-compose.override.yml up -d
docker compose -f update/docker-compose.yml -f update/docker-compose.override.yml create
docker compose -f update/docker-compose.yml -f update/docker-compose.override.yml up watchtower -d