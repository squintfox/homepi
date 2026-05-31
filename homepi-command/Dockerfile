# can't easily use Alpine with Bitwarden cli, so use Debian-based instead
FROM astral/uv:python3.14-bookworm-slim

ARG HPI_APP_UID=1000
ARG HPI_APP_GID=1000
# TODO: updatable
# https://github.com/opentofu/opentofu/releases
ARG OPENTOFU_VERSION=1.12.0
# TODO: updatable
# https://github.com/bitwarden/clients/releases (specifically CLI)
ARG BW_VERSION=2026.4.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        ca-certificates \
        git \
        nano \
        postgresql-client \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/app/.cache/uv \
    && chown -R ${HPI_APP_UID}:${HPI_APP_GID} /home/app

# install OpenTofu
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${ARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin tofu

# install bitwarden cli
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        BW_FILE="bw-linux-arm64-${BW_VERSION}.zip"; \
    else \
        BW_FILE="bw-linux-${BW_VERSION}.zip"; \
    fi \
    && curl -fsSL --retry 5 --retry-delay 5 "https://github.com/bitwarden/clients/releases/download/cli-v${BW_VERSION}/${BW_FILE}" \
        -o /tmp/bw.zip \
    && unzip /tmp/bw.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/bw \
    && rm /tmp/bw.zip

ENV HOME=/home/app
ENV UV_CACHE_DIR=/home/app/.cache/uv

WORKDIR /homepi

USER ${HPI_APP_UID}:${HPI_APP_GID}

# stay running
CMD ["tail", "-f", "/dev/null"]
