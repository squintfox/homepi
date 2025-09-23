#!/bin/bash

docker compose -f manage/docker-compose.yml -f manage/docker-compose.override.yml up -d
