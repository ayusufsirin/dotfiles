#!/usr/bin/env bash

nvim_offline_profile_keys=(
  NVIM_OFFLINE
  NVIM_NEXUS_URL
  NVIM_GITHUB_RELEASE_BASE_URL
  NVIM_NEXUS_GITHUB_URL
  NVIM_NEXUS_CORTEX_DEBUG_URL
  NVIM_NEXUS_PYPI_URL
  NVIM_NEXUS_NPM_URL
  NVIM_NEXUS_RAW_URL
  PIP_INDEX_URL
  NPM_CONFIG_REGISTRY
)

nvim_offline_is_profile_key() {
  local candidate="$1"
  local key
  for key in "${nvim_offline_profile_keys[@]}"; do
    if [[ "$candidate" == "$key" ]]; then
      return 0
    fi
  done
  return 1
}

nvim_offline_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

nvim_offline_load_profile() {
  local profile_file="$1"
  local line key value

  if [[ ! -r "$profile_file" ]]; then
    echo "Offline profile is missing or unreadable: $profile_file" >&2
    return 2
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(nvim_offline_trim "$line")"
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi
    if [[ ! "$line" =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]]; then
      echo "Invalid offline profile line: $line" >&2
      return 2
    fi

    key="${BASH_REMATCH[1]}"
    value="$(nvim_offline_trim "${BASH_REMATCH[2]}")"
    if ! nvim_offline_is_profile_key "$key"; then
      echo "Unknown offline profile setting: $key" >&2
      return 2
    fi
    if [[ ${#value} -ge 2 ]]; then
      if [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
        value="${value:1:${#value}-2}"
      elif [[ "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
        value="${value:1:${#value}-2}"
      fi
    fi

    # Values exported by the caller have precedence over the profile.
    if [[ ! -v "$key" ]]; then
      printf -v "$key" '%s' "$value"
      # key contains the variable name to export.
      # shellcheck disable=SC2163
      export "$key"
    fi
  done < "$profile_file"
}

nvim_offline_apply_defaults() {
  local nexus_url="${NVIM_NEXUS_URL:-}"
  nexus_url="${nexus_url%/}"

  if [[ -n "$nexus_url" ]]; then
    export NVIM_NEXUS_URL="$nexus_url"
    export NVIM_GITHUB_RELEASE_BASE_URL="${NVIM_GITHUB_RELEASE_BASE_URL:-${NVIM_NEXUS_GITHUB_URL:-$nexus_url/repository/github.com}}"
    export NVIM_NEXUS_CORTEX_DEBUG_URL="${NVIM_NEXUS_CORTEX_DEBUG_URL:-$nexus_url/repository/marketplace.visualstudio.com/_apis/public/gallery/publishers/marus25/vsextensions/cortex-debug/1.12.1/vspackage}"
    export NVIM_NEXUS_PYPI_URL="${NVIM_NEXUS_PYPI_URL:-${PIP_INDEX_URL:-$nexus_url/repository/pypi/simple}}"
    export NVIM_NEXUS_NPM_URL="${NVIM_NEXUS_NPM_URL:-${NPM_CONFIG_REGISTRY:-$nexus_url/repository/npm}}"
  fi
}
