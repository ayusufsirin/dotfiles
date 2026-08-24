#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_source="$repo_root/.config/nvim"

github_url="${NVIM_NEXUS_GITHUB_URL:-}"
raw_url="${NVIM_NEXUS_RAW_URL:-}"
cortex_debug_url="${NVIM_NEXUS_CORTEX_DEBUG_URL:-}"

if [[ -z "$github_url" && -z "$raw_url" ]]; then
  echo "Set NVIM_NEXUS_GITHUB_URL or legacy NVIM_NEXUS_RAW_URL" >&2
  exit 2
fi
if [[ -z "$cortex_debug_url" && -z "$raw_url" ]]; then
  echo "Set NVIM_NEXUS_CORTEX_DEBUG_URL or legacy NVIM_NEXUS_RAW_URL" >&2
  exit 2
fi

pypi_url="${NVIM_NEXUS_PYPI_URL:-${PIP_INDEX_URL:-}}"
npm_url="${NVIM_NEXUS_NPM_URL:-${NPM_CONFIG_REGISTRY:-}}"

if [[ -z "$pypi_url" ]]; then
  echo "Set NVIM_NEXUS_PYPI_URL or PIP_INDEX_URL" >&2
  exit 2
fi
if [[ -z "$npm_url" ]]; then
  echo "Set NVIM_NEXUS_NPM_URL or NPM_CONFIG_REGISTRY" >&2
  exit 2
fi

if [[ -n "${NVIM_OFFLINE_PRIME_ROOT:-}" ]]; then
  prime_tmp="$NVIM_OFFLINE_PRIME_ROOT"
  if [[ -e "$prime_tmp" ]]; then
    echo "NVIM_OFFLINE_PRIME_ROOT already exists: $prime_tmp" >&2
    exit 2
  fi
  mkdir -p "$prime_tmp"
else
  prime_tmp="$(mktemp -d)"
fi
cleanup() {
  if [[ "${NVIM_OFFLINE_KEEP_TMP:-0}" == "1" ]]; then
    echo "Kept isolated Neovim directory: $prime_tmp"
  else
    rm -rf -- "${prime_tmp:?}"
  fi
}
trap cleanup EXIT

mkdir -p "$prime_tmp/config" "$prime_tmp/data" "$prime_tmp/state" "$prime_tmp/cache"
ln -s "$config_source" "$prime_tmp/config/nvim"

export NVIM_OFFLINE=1
export NVIM_OFFLINE_PRIME=1
export NVIM_NEXUS_PYPI_URL="$pypi_url"
export NVIM_NEXUS_NPM_URL="$npm_url"
export XDG_CONFIG_HOME="$prime_tmp/config"
export XDG_DATA_HOME="$prime_tmp/data"
export XDG_STATE_HOME="$prime_tmp/state"
export XDG_CACHE_HOME="$prime_tmp/cache"

echo "Installing plugins through the configured Git mirror..."
nvim --headless "+Lazy! sync" +qa

echo "Installing pinned Mason tools through Nexus..."
nvim --headless "+Lazy load nvim-lspconfig" "+MasonToolsInstallSync" +qa

echo "Cloning and compiling Tree-sitter parsers through the Git mirror..."
nvim --headless "+lua vim.cmd('TSInstallSync! ' .. table.concat(require('config.offline').parsers, ' '))" +qa

echo "Running offline health checks..."
nvim --headless "+checkhealth nvim_offline" +qa

echo "Verifying pinned tools and parsers..."
nvim --headless "+luafile $config_source/tests/offline_install_verify.lua" +qa

echo "Offline bootstrap completed successfully. Nexus and Git mirrors contain the required content."
