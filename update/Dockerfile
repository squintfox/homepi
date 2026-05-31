FROM alpine:latest

# Install required packages
RUN apk add --no-cache git docker-cli docker-cli-compose curl bash

# Add entrypoints that prepare the environment and run the repo scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY entrypoint-restart.sh /usr/local/bin/entrypoint-restart.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint-restart.sh

WORKDIR /var/opt/homepi

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
