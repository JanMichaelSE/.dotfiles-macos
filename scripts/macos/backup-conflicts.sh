#!/usr/bin/env bash

set -euo pipefail

readonly BACKUP_BASE="${DOTFILES_BACKUP_DIR:-${HOME}/.dotfiles-backups}"
BACKUP_ROOT="${BACKUP_BASE}/$(date '+%Y%m%d-%H%M%S')-$$"
readonly BACKUP_ROOT
moved_any=false

backup_if_needed() {
  local target="$1"
  local relative destination

  if [[ -L "${target}" || ! -e "${target}" ]]; then
    return
  fi

  relative="${target#"${HOME}/"}"
  destination="${BACKUP_ROOT}/${relative}"
  mkdir -p "$(dirname "${destination}")"
  mv "${target}" "${destination}"
  printf 'Backed up %s -> %s\n' "${target}" "${destination}"
  moved_any=true
}

while IFS= read -r target; do
  backup_if_needed "${target}"
done <<EOF
${HOME}/.bash_profile
${HOME}/.bashrc
${HOME}/.zprofile
${HOME}/.zshrc
${HOME}/.zsh_plugins.txt
${HOME}/.p10k.zsh
${HOME}/.config/nvim
${HOME}/.config/ghostty/config
${HOME}/.config/ghostty/config.ghostty
${HOME}/.ssh/config
${HOME}/.tmux.conf
${HOME}/.gitconfig
${HOME}/.gitignore_global
${HOME}/.config/lazygit/config.yml
${HOME}/.config/surfingkeys/.surfingkeys.js
${HOME}/.config/bat
${HOME}/.config/mise/config.toml
${HOME}/.config/aerospace/aerospace.toml
${HOME}/.config/borders/bordersrc
${HOME}/Pictures/Wallpapers
EOF

if [[ "${moved_any}" == false ]]; then
  printf 'No conflicting files needed backup.\n'
fi
