#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly DOTFILES_DIR
readonly BREW_BIN="${BREW_BIN:-/opt/homebrew/bin/brew}"
readonly SYSTEM_APPLICATIONS_DIR="${SYSTEM_APPLICATIONS_DIR:-/Applications}"
readonly USER_APPLICATIONS_DIR="${USER_APPLICATIONS_DIR:-${HOME}/Applications}"
readonly USER_FONTS_DIR="${USER_FONTS_DIR:-${HOME}/Library/Fonts}"

if [[ ! -x "${BREW_BIN}" ]]; then
  printf 'Error: Homebrew is not available at %s.\n' "${BREW_BIN}" >&2
  exit 1
fi

explicitly_excluded_casks="${HOMEBREW_BUNDLE_CASK_SKIP:-}"
failed_casks=()
installed_count=0
managed_count=0
preserved_count=0
excluded_count=0
failed_count=0

cask_is_explicitly_excluded() {
  local cask="$1"

  case " ${explicitly_excluded_casks} " in
    *" ${cask} "*) return 0 ;;
    *) return 1 ;;
  esac
}

unmanaged_app_name() {
  local cask="$1"

  case "${cask}" in
    ghostty) printf '%s\n' 'Ghostty.app' ;;
    vivaldi) printf '%s\n' 'Vivaldi.app' ;;
    chatgpt) printf '%s\n' 'ChatGPT.app' ;;
    docker-desktop) printf '%s\n' 'Docker.app' ;;
    intellij-idea) printf '%s\n' 'IntelliJ IDEA.app' ;;
    visual-studio-code) printf '%s\n' 'Visual Studio Code.app' ;;
    bruno) printf '%s\n' 'Bruno.app' ;;
    notion) printf '%s\n' 'Notion.app' ;;
    whatsapp) printf '%s\n' 'WhatsApp.app' ;;
    spotify) printf '%s\n' 'Spotify.app' ;;
    maccy) printf '%s\n' 'Maccy.app' ;;
    macshot) printf '%s\n' 'macshot.app' ;;
    raycast) printf '%s\n' 'Raycast.app' ;;
    rectangle) printf '%s\n' 'Rectangle.app' ;;
    aerospace) printf '%s\n' 'AeroSpace.app' ;;
    logi-options+) printf '%s\n' 'logioptionsplus.app' ;;
    *) return 1 ;;
  esac
}

unmanaged_app_is_present() {
  local cask="$1"
  local app_name

  app_name="$(unmanaged_app_name "${cask}")" || return 1

  if [[ -e "${SYSTEM_APPLICATIONS_DIR}/${app_name}" \
    || -e "${USER_APPLICATIONS_DIR}/${app_name}" ]]; then
    printf '%s\n' "${app_name}"
    return 0
  fi

  # Homebrew currently installs MacShot with a lowercase bundle name, but also
  # preserve a manually installed bundle that uses the product's capitalization.
  if [[ "${cask}" == "macshot" ]] \
    && { [[ -e "${SYSTEM_APPLICATIONS_DIR}/MacShot.app" ]] \
      || [[ -e "${USER_APPLICATIONS_DIR}/MacShot.app" ]]; }; then
    printf '%s\n' 'MacShot.app'
    return 0
  fi

  return 1
}

formula_brewfile="$(mktemp "${TMPDIR:-/tmp}/dotfiles-formulae.XXXXXX")"
cleanup() {
  rm -f "${formula_brewfile}"
}
trap cleanup EXIT

# Keep Brewfile as the only package manifest while giving formulae and casks
# independent stages. This avoids Homebrew Bundle's misleading cask "Skipping"
# output and preserves formula options and dependency handling.
awk '!/^[[:space:]]*cask[[:space:]]/' \
  "${DOTFILES_DIR}/Brewfile" > "${formula_brewfile}"

printf '\n==> Stage 1/2: Homebrew formulae (required)\n'
if ! HOMEBREW_BUNDLE_NO_UPGRADE=1 \
  "${BREW_BIN}" bundle install \
  --file="${formula_brewfile}" \
  --no-upgrade; then
  printf '\nError: required Homebrew formulae could not be installed.\n' >&2
  printf 'The optional cask stage was not started. Fix the formula error, then rerun:\n' >&2
  printf '  %s\n' "${DOTFILES_DIR}/scripts/macos/brew-bundle.sh" >&2
  exit 1
fi

if ! declared_casks="$("${BREW_BIN}" bundle list --cask --file="${DOTFILES_DIR}/Brewfile")"; then
  printf 'Error: unable to read casks from %s/Brewfile.\n' "${DOTFILES_DIR}" >&2
  exit 1
fi

printf '\n==> Stage 2/2: Homebrew casks (optional)\n'
while IFS= read -r cask; do
  [[ -n "${cask}" ]] || continue

  if cask_is_explicitly_excluded "${cask}"; then
    printf '[excluded]  %s (HOMEBREW_BUNDLE_CASK_SKIP)\n' "${cask}"
    excluded_count=$((excluded_count + 1))
    continue
  fi

  if "${BREW_BIN}" list --cask "${cask}" >/dev/null 2>&1; then
    printf '[managed]   %s (already installed by Homebrew)\n' "${cask}"
    managed_count=$((managed_count + 1))
    continue
  fi

  if app_name="$(unmanaged_app_is_present "${cask}")"; then
    printf '[preserved] %s (existing %s outside Homebrew)\n' "${cask}" "${app_name}"
    preserved_count=$((preserved_count + 1))
    continue
  fi

  if [[ "${cask}" == "font-caskaydia-cove-nerd-font" ]] \
    && [[ -d "${USER_FONTS_DIR}" ]] \
    && [[ -n "$(find "${USER_FONTS_DIR}" -maxdepth 1 -iname 'CaskaydiaCove*' -print -quit)" ]]; then
    printf '[preserved] %s (existing CaskaydiaCove font outside Homebrew)\n' "${cask}"
    preserved_count=$((preserved_count + 1))
    continue
  fi

  printf '[installing] %s\n' "${cask}"
  if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 \
    "${BREW_BIN}" install --cask "${cask}"; then
    printf '[installed]  %s\n' "${cask}"
    installed_count=$((installed_count + 1))
  else
    printf '[deferred]   %s (installation failed; setup will continue)\n' "${cask}" >&2
    failed_casks[${#failed_casks[@]}]="${cask}"
    failed_count=$((failed_count + 1))
  fi
done <<< "${declared_casks}"

printf '\nCask summary: %s installed, %s already managed, %s externally preserved, %s excluded, %s deferred.\n' \
  "${installed_count}" "${managed_count}" "${preserved_count}" "${excluded_count}" "${failed_count}"

if (( failed_count > 0 )); then
  printf 'Optional casks were attempted once. Retry all deferred casks later with:\n' >&2
  printf '  brew install --cask' >&2
  for cask in "${failed_casks[@]}"; do
    printf ' %s' "${cask}" >&2
  done
  printf '\n' >&2
fi
