#!/usr/bin/env bash

# This script is intentionally opt-in and is never called by ./install.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly DOTFILES_DIR
readonly WALLPAPER_DIR="${DOTFILES_DIR}/config/backdrop/wallpapers"
wallpaper="${1:-${WALLPAPER_DIR}/Cityscape_hd.jpg}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Error: wallpapers can only be applied on macOS.\n' >&2
  exit 1
fi

if [[ "${wallpaper}" != /* ]]; then
  wallpaper="${WALLPAPER_DIR}/${wallpaper}"
fi

if [[ ! -f "${wallpaper}" ]]; then
  printf 'Error: wallpaper not found: %s\n' "${wallpaper}" >&2
  exit 1
fi

/usr/bin/osascript - "${wallpaper}" <<'APPLESCRIPT'
on run argv
  set wallpaperFile to POSIX file (item 1 of argv)
  tell application "System Events"
    tell every desktop to set picture to wallpaperFile
  end tell
end run
APPLESCRIPT

printf 'Wallpaper set to %s.\n' "${wallpaper}"
