#!/usr/bin/env bash

# This script is intentionally opt-in and is never called by ./install.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Error: macOS defaults can only be applied on macOS.\n' >&2
  exit 1
fi

screenshots_dir="${HOME}/Pictures/Screenshots"
mkdir -p "${screenshots_dir}"

# Finder: make file paths and extensions explicit for development work.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Screenshots: keep lossless PNGs out of the Desktop.
defaults write com.apple.screencapture location -string "${screenshots_dir}"
defaults write com.apple.screencapture type -string "png"

killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

printf 'Applied opt-in Finder and screenshot defaults.\n'
