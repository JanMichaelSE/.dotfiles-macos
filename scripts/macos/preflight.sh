#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Error: these dotfiles support macOS only.\n' >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  printf 'Error: these dotfiles require an Apple Silicon Mac (arm64).\n' >&2
  exit 1
fi

if ! /usr/bin/xcode-select --print-path >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Error: Xcode Command Line Tools are required.

Run `xcode-select --install`, finish the installation, and then run ./install
again. Homebrew will be bootstrapped on the next run.
EOF
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  printf 'Error: macOS curl is required to bootstrap Homebrew.\n' >&2
  exit 1
fi

printf 'macOS Apple Silicon and Xcode Command Line Tools are ready.\n'
