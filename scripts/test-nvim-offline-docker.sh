#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dockerfile="$repo_root/tests/docker/nvim-offline/Dockerfile"
nexus_url="${NVIM_TEST_NEXUS_URL:-http://nexus.company.example:8081}"
nexus_host="$(printf '%s' "$nexus_url" | sed -E 's#^https?://([^/:]+).*#\1#')"
mirror_base="${NVIM_TEST_GITHUB_MIRROR_BASE:-https://gitlab.company.example/mirror/github.com/}"
docker_network="${NVIM_TEST_DOCKER_NETWORK:-default}"
pull_bases="${NVIM_TEST_PULL_BASES:-1}"
debian_image="${NVIM_TEST_DEBIAN_IMAGE:-debian:12}"
ubuntu_image="${NVIM_TEST_UBUNTU_IMAGE:-ubuntu:22.04}"
ca_file="${NVIM_TEST_GITLAB_CA_FILE:-/usr/local/share/ca-certificates/company-internal-ca.crt}"
token_file="${NVIM_TEST_GITLAB_TOKEN_FILE:-}"
temporary_token_file=""

cleanup() {
  if [[ -n "$temporary_token_file" && -f "$temporary_token_file" ]]; then
    find "$temporary_token_file" -delete
  fi
}
trap cleanup EXIT

if [[ "$mirror_base" != */ ]]; then
  mirror_base="$mirror_base/"
fi

if [[ "$mirror_base" != http://localhost:* && "$mirror_base" != http://127.0.0.1:* ]]; then
  if [[ -z "$token_file" ]]; then
    if [[ ! -t 0 ]]; then
      echo "Set NVIM_TEST_GITLAB_TOKEN_FILE when running non-interactively." >&2
      exit 2
    fi
    temporary_token_file="$(mktemp)"
    chmod 600 "$temporary_token_file"
    read -r -s -p "GitLab mirror read token: " token
    echo
    printf '%s' "$token" > "$temporary_token_file"
    unset token
    token_file="$temporary_token_file"
  fi
  if [[ ! -s "$token_file" ]]; then
    echo "GitLab token file is missing or empty: $token_file" >&2
    exit 2
  fi
fi

if [[ "$pull_bases" == "1" ]]; then
  docker pull "$debian_image"
  docker pull "$ubuntu_image"
fi

secret_args=()
if [[ -n "$token_file" ]]; then
  secret_args+=(--secret "id=gitlab_token,src=$token_file")
fi
if [[ -r "$ca_file" ]]; then
  secret_args+=(--secret "id=gitlab_ca,src=$ca_file")
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
    --build-arg "GITHUB_MIRROR_BASE=$mirror_base" \
    "${secret_args[@]}" \
    "$repo_root"

  docker run --rm "$tag"

  if [[ -n "$token_file" ]]; then
    local token token_base64
    token="$(<"$token_file")"
    token_base64="$(printf 'oauth2:%s' "$token" | base64 | tr -d '\n')"
    if docker history --no-trunc --format '{{.CreatedBy}}' "$tag" | grep -Fq -- "$token"; then
      echo "GitLab token leaked into Docker history for $tag" >&2
      return 1
    fi
    if docker inspect --format '{{json .Config.Env}}' "$tag" | grep -Fq -- "$token"; then
      echo "GitLab token leaked into the image environment for $tag" >&2
      return 1
    fi
    if docker history --no-trunc --format '{{.CreatedBy}}' "$tag" | grep -Fq -- "$token_base64"; then
      echo "Encoded GitLab credentials leaked into Docker history for $tag" >&2
      return 1
    fi
    unset token token_base64
  fi
}

build_one debian "$debian_image"
build_one ubuntu "$ubuntu_image"

echo "Debian 12 and Ubuntu 22.04 offline Neovim installations passed."
