#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/nvim-offline-profile.sh
source "$repo_root/scripts/lib/nvim-offline-profile.sh"

profile_file="${NVIM_OFFLINE_PROFILE:-$HOME/.config/nvim-offline/env}"
preflight_only=0

usage() {
  cat <<'EOF'
Usage: scripts/setup-nvim-offline.sh [--profile FILE] [--preflight-only]

Validates a target machine, warms/verifies all Git mirrors, and performs an
isolated offline Neovim installation. It never installs OS packages, changes
global Git URL settings, or stores credentials.
EOF
}

while (($# > 0)); do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { echo "--profile requires a file" >&2; exit 2; }
      profile_file="$2"
      shift 2
      ;;
    --preflight-only)
      preflight_only=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

nvim_offline_load_profile "$profile_file"
nvim_offline_apply_defaults
nvim_offline_apply_git_environment
export NVIM_OFFLINE_PROFILE="$profile_file"

if [[ "${NVIM_OFFLINE:-}" != "1" ]]; then
  echo "Set NVIM_OFFLINE=1 in $profile_file" >&2
  exit 2
fi

missing=()
for command_name in nvim git curl tar gzip unzip python3 node npm; do
  command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done
if ! command -v rg >/dev/null 2>&1; then
  missing+=("ripgrep")
fi
if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
  missing+=("fd/fdfind")
fi
if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
  missing+=("C compiler")
fi
if ((${#missing[@]} > 0)); then
  printf 'Missing prerequisites: %s\n' "$(IFS=', '; echo "${missing[*]}")" >&2
  echo "Debian/Ubuntu packages: neovim git curl tar gzip unzip ripgrep fd-find python3 python3-venv nodejs npm build-essential" >&2
  exit 2
fi

nvim_version="$(nvim --version | sed -n '1s/^NVIM v//p')"
if [[ ! "$nvim_version" =~ ^([0-9]+)\.([0-9]+)\. ]]; then
  echo "Unable to parse Neovim version: ${nvim_version:-unknown}" >&2
  exit 2
fi
nvim_major="${BASH_REMATCH[1]}"
nvim_minor="${BASH_REMATCH[2]}"
if ((10#$nvim_major == 0 && 10#$nvim_minor < 10)); then
  echo "Neovim 0.10 or newer is required; found ${nvim_version:-unknown}" >&2
  exit 2
fi

if [[ -z "$(git config --get credential.helper 2>/dev/null || true)" ]]; then
  echo "Configure a Git credential helper before running offline setup." >&2
  exit 2
fi

profile_mode="$(stat -c '%a' "$profile_file" 2>/dev/null || stat -f '%Lp' "$profile_file")"
if ((8#$profile_mode & 077)); then
  echo "Offline profile must not be accessible by group or others: chmod 600 $profile_file" >&2
  exit 2
fi

manifest_file="$(mktemp)"
cleanup() {
  find "$manifest_file" -delete 2>/dev/null || true
}
trap cleanup EXIT

NVIM_DOTFILES_ROOT="$repo_root" nvim --headless --clean -u NONE \
  "+luafile $repo_root/scripts/nvim-offline-git-manifest.lua" +qa > "$manifest_file"

mirror_base="${NVIM_GITHUB_GIT_MIRROR_BASE%/}/"
repository_count=0
while IFS= read -r source_url; do
  [[ -n "$source_url" ]] || continue
  repository_count=$((repository_count + 1))
  if [[ ! "$source_url" =~ \.git$ ]]; then
    echo "Clone URL is missing .git: $source_url" >&2
    exit 1
  fi
  resolved_url="$mirror_base${source_url#https://github.com/}"
  printf 'Checking %s\n' "$resolved_url"
  GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$resolved_url" HEAD >/dev/null
done < "$manifest_file"
printf 'Verified %d Git repositories through the mirror.\n' "$repository_count"

registry_version="$(NVIM_DOTFILES_ROOT="$repo_root" nvim --headless --clean -u NONE \
  "+lua package.path='$repo_root/.config/nvim/lua/?.lua;$repo_root/.config/nvim/lua/?/init.lua;' .. package.path; io.write(require('config.offline').registry_version)" +qa)"
for endpoint in \
  "$NVIM_GITHUB_RELEASE_BASE_URL/mason-org/mason-registry/releases/download/$registry_version/checksums.txt" \
  "$NVIM_NEXUS_CORTEX_DEBUG_URL" \
  "${NVIM_NEXUS_PYPI_URL%/}/" \
  "${NVIM_NEXUS_NPM_URL%/}/"; do
  printf 'Checking %s\n' "$endpoint"
  curl --fail --silent --show-error --location --max-time 20 --range 0-0 --output /dev/null "$endpoint"
done
echo "Nexus endpoints are reachable."

if [[ "$preflight_only" == "1" ]]; then
  echo "Offline Neovim preflight passed."
  exit 0
fi

config_parent="${XDG_CONFIG_HOME:-$HOME/.config}"
config_target="$config_parent/nvim"
config_source="$repo_root/.config/nvim"
mkdir -p "$config_parent"
if [[ -L "$config_target" ]]; then
  if [[ "$(readlink -f "$config_target")" != "$(readlink -f "$config_source")" ]]; then
    echo "Existing Neovim symlink points elsewhere: $config_target" >&2
    exit 2
  fi
elif [[ -e "$config_target" ]]; then
  echo "Existing Neovim configuration will not be replaced: $config_target" >&2
  exit 2
else
  ln -s "$config_source" "$config_target"
fi

"$repo_root/scripts/nvim-offline-prime.sh"
echo "Offline workstation setup completed. Launch nvim normally."
