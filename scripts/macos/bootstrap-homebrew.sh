#!/usr/bin/env bash

set -euo pipefail

readonly BREW_BIN="/opt/homebrew/bin/brew"
readonly INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

if [[ -x "${BREW_BIN}" ]]; then
  printf 'Homebrew is already installed at /opt/homebrew.\n'
else
  printf 'Homebrew is not installed; starting the official Homebrew installer.\n'
  /bin/bash -c "$(curl -fsSL "${INSTALL_URL}")"
fi

if [[ ! -x "${BREW_BIN}" ]]; then
  printf 'Error: Homebrew was not installed at /opt/homebrew.\n' >&2
  exit 1
fi

actual_prefix="$(${BREW_BIN} --prefix)"
if [[ "${actual_prefix}" != "/opt/homebrew" ]]; then
  printf 'Error: expected the Apple Silicon Homebrew prefix, got %s.\n' "${actual_prefix}" >&2
  exit 1
fi

eval "$(${BREW_BIN} shellenv)"
printf 'Homebrew %s is ready.\n' "$(${BREW_BIN} --version | head -n 1)"
