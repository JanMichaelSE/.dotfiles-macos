#!/usr/bin/env bash

# Static verification is read-only and requires no software installation.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly DOTFILES_DIR
readonly MARKDOWN_PREVIEW_APP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/lazy/markdown-preview.nvim/app"
check_installed=false
failures=0
warnings=0

if [[ "${1:-}" == "--installed" ]]; then
  check_installed=true
  shift
fi

if [[ "$#" -ne 0 ]]; then
  printf 'Usage: %s [--installed]\n' "$0" >&2
  exit 2
fi

pass() {
  printf 'ok: %s\n' "$1"
}

fail() {
  printf 'not ok: %s\n' "$1" >&2
  failures=$((failures + 1))
}

warn() {
  printf 'warning: %s\n' "$1" >&2
  warnings=$((warnings + 1))
}

require_file() {
  if [[ -f "${DOTFILES_DIR}/$1" ]]; then
    pass "$1 exists"
  else
    fail "$1 is missing"
  fi
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is available"
  else
    fail "$1 is not available"
  fi
}

require_app() {
  local app_name="$1"

  if [[ -d "/Applications/${app_name}" || -d "${HOME}/Applications/${app_name}" ]]; then
    pass "${app_name} is installed"
  else
    warn "${app_name} is not installed"
  fi
}

require_markdown_preview_runtime() {
  if [[ ! -f "${MARKDOWN_PREVIEW_APP_DIR}/package.json" ]]; then
    fail 'markdown-preview.nvim is not installed'
    return
  fi

  if (
    cd "${MARKDOWN_PREVIEW_APP_DIR}"
    node -e '
      const dependencies = Object.keys(require("./package.json").dependencies || {});
      for (const dependency of dependencies) require.resolve(dependency);
    '
  ) >/dev/null 2>&1; then
    pass 'markdown-preview.nvim Node.js dependencies are available'
  else
    fail 'markdown-preview.nvim Node.js dependencies are incomplete'
  fi
}

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  pass 'host is Apple Silicon macOS'
else
  fail 'host must be Apple Silicon macOS'
fi

for file in \
  Brewfile \
  install.conf.yaml \
  config/mise/config.toml \
  config/bash/bash_profile \
  bashrc \
  config/zsh/zprofile \
  config/zsh/zshrc \
  config/aerospace/aerospace.toml \
  config/borders/bordersrc \
  config/zsh/zsh_plugins.txt \
  config/ghostty/config.ghostty \
  config/git/gitconfig \
  config/git/gitignore_global \
  config/ssh/config; do
  require_file "${file}"
done

for script in "${DOTFILES_DIR}/install" "${DOTFILES_DIR}"/scripts/macos/*.sh; do
  if /bin/bash -n "${script}"; then
    pass "${script#"${DOTFILES_DIR}/"} has valid Bash syntax"
  else
    fail "${script#"${DOTFILES_DIR}/"} has invalid Bash syntax"
  fi
done

if command -v ruby >/dev/null 2>&1; then
  if ruby -c "${DOTFILES_DIR}/Brewfile" >/dev/null; then
    pass 'Brewfile has valid Ruby syntax'
  else
    fail 'Brewfile has invalid Ruby syntax'
  fi
fi

if PYTHONPATH="${DOTFILES_DIR}/dotbot/lib/pyyaml/lib" /usr/bin/python3 - "${DOTFILES_DIR}/install.conf.yaml" <<'PY'
import sys
import yaml

with open(sys.argv[1], encoding="utf-8") as stream:
    yaml.safe_load(stream)
PY
then
  pass 'install.conf.yaml has valid YAML syntax'
else
  fail 'install.conf.yaml has invalid YAML syntax'
fi

if [[ "${check_installed}" == true ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    fail 'Homebrew is not installed at /opt/homebrew'
  fi

  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
  else
    fail 'mise is not available, so managed runtimes cannot be activated'
  fi
  export PATH="${HOME}/.local/bin:${PATH}"

  if [[ -x /opt/homebrew/bin/bash ]]; then
    pass 'Homebrew Bash is available at /opt/homebrew/bin/bash'
  else
    fail 'Homebrew Bash is not available at /opt/homebrew/bin/bash'
  fi

  for command_name in \
    brew git gh lazygit delta nvim tmux bat eza fd fzf rg tree \
    tree-sitter jq wget shellcheck htop trash yazi zoxide ffmpeg 7zz \
    pdftotext magick lazydocker sshs kubectl minikube k9s mise nodenv pyenv dlv \
    mvn gradle stylua node npm python3 go rustc cargo java terraform terragrunt \
    tsc eslint bash-language-server codex aerospace borders; do
    require_command "${command_name}"
  done

  require_markdown_preview_runtime

  if command -v docker >/dev/null 2>&1; then
    pass 'Docker CLI is available'
  else
    warn 'Docker CLI is not available'
  fi

  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    pass 'Docker Compose is available'
  else
    warn 'Docker Compose is not available'
  fi

  if command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; then
    pass 'Docker Buildx is available'
  else
    warn 'Docker Buildx is not available'
  fi

  for app_name in \
    Ghostty.app Vivaldi.app ChatGPT.app Discord.app Docker.app "IntelliJ IDEA.app" "Visual Studio Code.app" \
    Bruno.app Notion.app WhatsApp.app Spotify.app Maccy.app macshot.app \
    Raycast.app Rectangle.app AeroSpace.app logioptionsplus.app Intent.app; do
    require_app "${app_name}"
  done

  font_installed=false
  if [[ -x /opt/homebrew/bin/brew ]] \
    && /opt/homebrew/bin/brew list --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1; then
    font_installed=true
  elif [[ -d "${HOME}/Library/Fonts" ]] \
    && [[ -n "$(find "${HOME}/Library/Fonts" -maxdepth 1 -iname 'CaskaydiaCove*' -print -quit)" ]]; then
    font_installed=true
  fi

  if [[ "${font_installed}" == true ]]; then
    pass 'CaskaydiaCove Nerd Font is installed'
  else
    warn 'CaskaydiaCove Nerd Font is not installed'
  fi
fi

if [[ "${failures}" -gt 0 ]]; then
  printf '\nVerification failed with %s problem(s).\n' "${failures}" >&2
  exit 1
fi

if [[ "${warnings}" -gt 0 ]]; then
  printf '\nVerification passed with %s optional warning(s).\n' "${warnings}"
else
  printf '\nVerification passed.\n'
fi
