#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dockerfile="$repo_root/tests/docker/nvim-offline/Dockerfile"

env_file="${NVIM_TEST_ENV_FILE:-$repo_root/.env}"
env_names=(
  NVIM_NEXUS_URL
  NVIM_TEST_NEXUS_URL
  NVIM_TEST_DOCKER_NETWORK
  NVIM_TEST_PULL_BASES
  NVIM_TEST_DEBIAN_IMAGE
  NVIM_TEST_UBUNTU_IMAGE
  NVIM_TEST_GIT_CONFIG_FILE
  NVIM_TEST_INTERNAL_CA_FILE
)
declare -A caller_environment=()
for env_name in "${env_names[@]}"; do
  if [[ -v "$env_name" ]]; then
    caller_environment["$env_name"]="${!env_name}"
  fi
done

if [[ -f "$env_file" ]]; then
  set -a
  # .env is a trusted local shell-format configuration file.
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
elif [[ -n "${NVIM_TEST_ENV_FILE:-}" ]]; then
  echo "NVIM test environment file does not exist: $env_file" >&2
  exit 2
fi

# Explicit caller environment always wins over the local .env file.
for env_name in "${!caller_environment[@]}"; do
  printf -v "$env_name" '%s' "${caller_environment[$env_name]}"
  # env_name contains the variable name to export.
  # shellcheck disable=SC2163
  export "$env_name"
done

nexus_url="${NVIM_TEST_NEXUS_URL:-${NVIM_NEXUS_URL:-http://nexus.company.example:8081}}"
nexus_host="$(printf '%s' "$nexus_url" | sed -E 's#^https?://([^/:]+).*#\1#')"
docker_network="${NVIM_TEST_DOCKER_NETWORK:-default}"
pull_bases="${NVIM_TEST_PULL_BASES:-1}"
debian_image="${NVIM_TEST_DEBIAN_IMAGE:-debian:12}"
ubuntu_image="${NVIM_TEST_UBUNTU_IMAGE:-ubuntu:22.04}"
git_config_file="${NVIM_TEST_GIT_CONFIG_FILE:-$HOME/.gitconfig}"
ca_file="${NVIM_TEST_INTERNAL_CA_FILE:-}"

if [[ ! -r "$git_config_file" ]]; then
  echo "Git config is missing or unreadable: $git_config_file" >&2
  echo "Set NVIM_TEST_GIT_CONFIG_FILE to a self-contained Git config that can clone the canonical GitHub URLs." >&2
  exit 2
fi

if [[ "$pull_bases" == "1" ]]; then
  docker pull "$debian_image"
  docker pull "$ubuntu_image"
fi

secret_args=(--secret "id=git_config,src=$git_config_file")
if [[ -r "$ca_file" ]]; then
  secret_args+=(--secret "id=internal_ca,src=$ca_file")
fi

build_one() {
  local distro="$1"
  local base_image="$2"
  local tag="nvim-offline-test:${distro}"

  echo "Building clean offline Neovim image for $base_image..."
  docker build \
    --file "$dockerfile" \
    --tag "$tag" \
    --no-cache \
    --pull=false \
    --network "$docker_network" \
    --progress plain \
    --build-arg "BASE_IMAGE=$base_image" \
    --build-arg "DISTRO=$distro" \
    --build-arg "NEXUS_URL=$nexus_url" \
    --build-arg "NEXUS_HOST=$nexus_host" \
    "${secret_args[@]}" \
    "$repo_root"

  docker run --rm "$tag"
  docker run --rm "$tag" sh -c 'test ! -e "$HOME/.gitconfig"'
}

build_one debian "$debian_image"
build_one ubuntu "$ubuntu_image"

echo "Debian 12 and Ubuntu 22.04 offline Neovim installations passed."
