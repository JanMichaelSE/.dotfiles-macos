#!/usr/bin/env bash

# AeroSpace is more reliable with one shared macOS Space across displays.
# This script is intentionally separate from ./install because it changes a
# system preference and requires a logout before macOS applies it.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Error: AeroSpace display settings can only be applied on macOS.\n' >&2
  exit 1
fi

# Invert the System Settings label: true means displays do *not* have separate
# macOS Spaces. AeroSpace manages its own shared workspace pool instead.
defaults write com.apple.spaces spans-displays -bool true

printf '%s\n' \
  'Configured macOS to disable “Displays have separate Spaces” for AeroSpace.' \
  'Log out and back in before connecting or using multiple displays.'
