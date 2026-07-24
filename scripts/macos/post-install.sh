#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly DOTFILES_DIR
readonly MISE_BIN="${MISE_BIN:-/opt/homebrew/bin/mise}"
readonly TPM_DIR="${HOME}/.tmux/plugins/tpm"
TPM_TMUX_TMPDIR=""

if [[ -d "/Applications/Docker.app/Contents/Resources" ]]; then
  readonly DOCKER_RESOURCES="/Applications/Docker.app/Contents/Resources"
elif [[ -d "${HOME}/Applications/Docker.app/Contents/Resources" ]]; then
  readonly DOCKER_RESOURCES="${HOME}/Applications/Docker.app/Contents/Resources"
else
  readonly DOCKER_RESOURCES=""
fi

link_docker_tool() {
  local source="$1"
  local destination="$2"

  if [[ ! -x "${source}" ]]; then
    return
  fi

  # Replace only links created by an earlier run. Never overwrite a user's
  # regular file or locally managed executable.
  if [[ -L "${destination}" ]]; then
    ln -sfn "${source}" "${destination}"
  elif [[ ! -e "${destination}" ]]; then
    ln -s "${source}" "${destination}"
  fi
}

cleanup_tpm_server() {
  if [[ -z "${TPM_TMUX_TMPDIR}" ]]; then
    return
  fi

  # TMUX_TMPDIR keeps this bootstrap server isolated from any live sessions.
  (
    unset TMUX TMUX_PANE
    TMUX_TMPDIR="${TPM_TMUX_TMPDIR}" tmux kill-server >/dev/null 2>&1 || true
  )
  rm -rf "${TPM_TMUX_TMPDIR}"
  TPM_TMUX_TMPDIR=""
}

install_tmux_plugins() {
  TPM_TMUX_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tpm.XXXXXX")"
  chmod 700 "${TPM_TMUX_TMPDIR}"
  trap cleanup_tpm_server EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM

  # TPM's CLI discovers @plugin declarations and its install directory through
  # tmux. Use a private socket so an older or customized live tmux server cannot
  # leak stale configuration into bootstrap (and bootstrap cannot alter it).
  (
    unset TMUX TMUX_PANE
    TMUX_TMPDIR="${TPM_TMUX_TMPDIR}" "${TPM_DIR}/bin/install_plugins"
  )

  cleanup_tpm_server
  trap - EXIT HUP INT TERM
}

run_with_managed_runtimes() {
  if [[ -x "${MISE_BIN}" ]]; then
    MISE_GLOBAL_CONFIG_FILE="${DOTFILES_DIR}/config/mise/config.toml" \
      MISE_GLOBAL_CONFIG_ROOT="${HOME}" \
      "${MISE_BIN}" exec -- "$@"
  else
    "$@"
  fi
}

if [[ -n "${DOCKER_RESOURCES}" ]]; then
  mkdir -p "${HOME}/.local/bin" "${HOME}/.docker/cli-plugins"
  link_docker_tool "${DOCKER_RESOURCES}/bin/docker" "${HOME}/.local/bin/docker"

  for source in "${DOCKER_RESOURCES}"/bin/docker-credential-*; do
    [[ -x "${source}" ]] || continue
    link_docker_tool "${source}" "${HOME}/.local/bin/$(basename "${source}")"
  done

  for source in "${DOCKER_RESOURCES}"/cli-plugins/docker-*; do
    [[ -x "${source}" ]] || continue
    link_docker_tool "${source}" "${HOME}/.docker/cli-plugins/$(basename "${source}")"
  done
fi

if [[ ! -d "${TPM_DIR}/.git" ]]; then
  if [[ -e "${TPM_DIR}" ]]; then
    printf 'Error: %s exists but is not a TPM Git checkout.\n' "${TPM_DIR}" >&2
    exit 1
  fi
  mkdir -p "$(dirname "${TPM_DIR}")"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "${TPM_DIR}"
fi

install_tmux_plugins

if command -v zsh >/dev/null 2>&1; then
  zsh -ic exit
fi

if command -v bat >/dev/null 2>&1; then
  bat cache --build
fi

if command -v nvim >/dev/null 2>&1; then
  run_with_managed_runtimes nvim --headless "+Lazy! sync" +qa
  run_with_managed_runtimes \
    "${DOTFILES_DIR}/scripts/macos/ensure-markdown-preview.sh"
fi

printf 'Docker CLI, Zsh, TPM, bat, and Neovim plugin setup is ready.\n'
