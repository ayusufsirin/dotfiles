# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=debian:12
FROM ${BASE_IMAGE}

ARG DISTRO=debian
ARG NEXUS_URL=http://nexus.company.example:8081
ARG NEXUS_HOST=nexus.company.example
ARG GITHUB_MIRROR_BASE=https://gitlab.company.example/mirror/github.com/
ARG NEOVIM_VERSION=0.12.3
ARG NEOVIM_SHA256=5709e7f3653c9ccc96bb78e79ae1ad3b1191f34d12075f27c469f702f301a2e8
ARG NODE_VERSION=22.23.2
ARG NODE_SHA256=d60acfe00a2932254bb0ad20e01b0d74397a0875595de719654b214f4b03f307

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    case "$DISTRO" in \
      debian) \
        printf '%s\n' \
          "deb ${NEXUS_URL}/repository/debian/debian bookworm main" \
          "deb ${NEXUS_URL}/repository/debian/debian bookworm-updates main" \
          "deb ${NEXUS_URL}/repository/security.debian.org/debian-security bookworm-security main" \
          > /etc/apt/sources.list; \
        ;; \
      ubuntu) \
        printf '%s\n' \
          "deb ${NEXUS_URL}/repository/ubuntu jammy main restricted universe multiverse" \
          "deb ${NEXUS_URL}/repository/ubuntu jammy-updates main restricted universe multiverse" \
          "deb ${NEXUS_URL}/repository/ubuntu jammy-backports main restricted universe multiverse" \
          "deb ${NEXUS_URL}/repository/security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse" \
          > /etc/apt/sources.list; \
        ;; \
      *) echo "Unsupported DISTRO: $DISTRO" >&2; exit 2 ;; \
    esac; \
    find /etc/apt/sources.list.d -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      fd-find \
      git \
      gzip \
      python3 \
      python3-venv \
      ripgrep \
      tar \
      unzip \
      xz-utils; \
    find /var/lib/apt/lists -mindepth 1 -delete

RUN --mount=type=secret,id=gitlab_ca,required=false \
    set -eux; \
    if [ -s /run/secrets/gitlab_ca ]; then \
      cp /run/secrets/gitlab_ca /usr/local/share/ca-certificates/gitlab-internal.crt; \
      update-ca-certificates; \
    fi

RUN set -eux; \
    node_archive="node-v${NODE_VERSION}-linux-x64.tar.xz"; \
    curl --fail --location --show-error \
      "${NEXUS_URL}/repository/nodejs.org/dist/v${NODE_VERSION}/${node_archive}" \
      --output "/tmp/${node_archive}"; \
    echo "${NODE_SHA256}  /tmp/${node_archive}" | sha256sum --check --strict; \
    tar -xJf "/tmp/${node_archive}" -C /usr/local --strip-components=1; \
    rm "/tmp/${node_archive}"; \
    node --version; \
    npm --version

RUN set -eux; \
    nvim_appimage="/tmp/nvim-linux-x86_64.appimage"; \
    curl --fail --location --show-error \
      "${NEXUS_URL}/repository/github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.appimage" \
      --output "$nvim_appimage"; \
    echo "${NEOVIM_SHA256}  ${nvim_appimage}" | sha256sum --check --strict; \
    chmod +x "$nvim_appimage"; \
    cd /tmp; \
    "$nvim_appimage" --appimage-extract >/dev/null; \
    mv /tmp/squashfs-root /opt/nvim; \
    ln -s /opt/nvim/AppRun /usr/local/bin/nvim; \
    rm "$nvim_appimage"; \
    nvim --version | head -1

RUN useradd --create-home --shell /bin/bash nvimtest

COPY --chown=nvimtest:nvimtest .config/nvim /home/nvimtest/.dotfiles/.config/nvim
COPY --chown=nvimtest:nvimtest scripts/nvim-offline-prime.sh /home/nvimtest/.dotfiles/scripts/nvim-offline-prime.sh

USER nvimtest
WORKDIR /home/nvimtest/.dotfiles

ENV HOME=/home/nvimtest \
    NVIM_OFFLINE=1 \
    NVIM_NEXUS_GITHUB_URL=${NEXUS_URL}/repository/github.com \
    NVIM_NEXUS_CORTEX_DEBUG_URL=${NEXUS_URL}/repository/marketplace.visualstudio.com/_apis/public/gallery/publishers/marus25/vsextensions/cortex-debug/1.12.1/vspackage \
    NVIM_NEXUS_PYPI_URL=${NEXUS_URL}/repository/pypi/simple \
    NVIM_NEXUS_NPM_URL=${NEXUS_URL}/repository/npm \
    PIP_TRUSTED_HOST=${NEXUS_HOST} \
    GIT_TERMINAL_PROMPT=0 \
    GIT_PROGRESS_DELAY=999999

RUN --mount=type=secret,id=gitlab_token,required=false \
    set -eu; \
    export GIT_CONFIG_COUNT=1; \
    export GIT_CONFIG_KEY_0="url.${GITHUB_MIRROR_BASE}.insteadOf"; \
    export GIT_CONFIG_VALUE_0="https://github.com/"; \
    if [ -s /run/secrets/gitlab_token ]; then \
      mirror_host=$(printf '%s' "$GITHUB_MIRROR_BASE" | sed -E 's#^https?://([^/]+)/.*#\1#'); \
      basic_auth=$(printf 'oauth2:%s' "$(cat /run/secrets/gitlab_token)" | base64 | tr -d '\n'); \
      export GIT_CONFIG_COUNT=2; \
      export GIT_CONFIG_KEY_1="http.https://${mirror_host}/.extraHeader"; \
      export GIT_CONFIG_VALUE_1="Authorization: Basic ${basic_auth}"; \
    fi; \
    resolved=$(git ls-remote --get-url https://github.com/nvim-lua/plenary.nvim.git); \
    case "$resolved" in "$GITHUB_MIRROR_BASE"*) ;; *) echo "GitHub mirror rewrite failed" >&2; exit 1 ;; esac; \
    ./scripts/nvim-offline-prime.sh

RUN test "$(nvim --version | head -1)" = "NVIM v${NEOVIM_VERSION}"; \
    test "$(node --version)" = "v${NODE_VERSION}"

CMD ["nvim", "--headless", "--clean", "+lua print('offline Docker validation image is ready')", "+qa"]
