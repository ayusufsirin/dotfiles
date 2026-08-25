#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
profile_file="$repo_root/tests/nvim-offline/profile.env"
# shellcheck source=scripts/lib/nvim-offline-profile.sh
source "$repo_root/scripts/lib/nvim-offline-profile.sh"

invalid_profile="$(mktemp)"
cleanup() {
  find "$invalid_profile" -delete 2>/dev/null || true
}
trap cleanup EXIT
printf 'UNKNOWN_OFFLINE_SETTING=value\n' > "$invalid_profile"
if (nvim_offline_load_profile "$invalid_profile" >/dev/null 2>&1); then
  echo "Unknown profile settings should be rejected" >&2
  exit 1
fi

(
  unset NVIM_OFFLINE NVIM_NEXUS_URL NVIM_GITHUB_GIT_MIRROR_BASE
  nvim_offline_load_profile "$profile_file"
  nvim_offline_apply_defaults
  [[ "$NVIM_OFFLINE" == "1" ]]
  [[ "$NVIM_GITHUB_RELEASE_BASE_URL" == "http://nexus.invalid/repository/github.com" ]]
  [[ "$NVIM_NEXUS_PYPI_URL" == "http://nexus.invalid/repository/pypi/simple" ]]
)

(
  export NVIM_NEXUS_URL="http://caller.invalid"
  unset NVIM_OFFLINE NVIM_GITHUB_GIT_MIRROR_BASE
  nvim_offline_load_profile "$profile_file"
  [[ "$NVIM_NEXUS_URL" == "http://caller.invalid" ]]
)

env \
  -u NVIM_OFFLINE \
  -u NVIM_NEXUS_URL \
  -u NVIM_GITHUB_GIT_MIRROR_BASE \
  NVIM_OFFLINE_PROFILE="$profile_file" \
  nvim --headless --clean -u NONE \
  "+lua package.path='$repo_root/.config/nvim/lua/?.lua;$repo_root/.config/nvim/lua/?/init.lua;' .. package.path" \
  "+luafile $repo_root/.config/nvim/tests/offline_profile.lua" +qa

manifest="$(NVIM_DOTFILES_ROOT="$repo_root" nvim --headless --clean -u NONE \
  "+luafile $repo_root/scripts/nvim-offline-git-manifest.lua" +qa)"
repository_count="$(printf '%s\n' "$manifest" | sed '/^$/d' | wc -l)"
[[ "$repository_count" -ge 60 ]]
[[ "$(printf '%s\n' "$manifest" | sort -u | wc -l)" == "$repository_count" ]]
if printf '%s\n' "$manifest" | awk 'NF && $0 !~ /^https:\/\/github\.com\/.+\.git$/ { exit 1 }'; then
  :
else
  echo "Manifest contains a non-canonical Git URL" >&2
  exit 1
fi

echo "Offline profile and Git manifest tests passed."
