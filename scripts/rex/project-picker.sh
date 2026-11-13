#!/usr/bin/env bash
# Rex port of scripts/tmux/project-picker.sh. Runs inside a floating Rex pane
# opened by the `project_picker` action in ~/.config/rex/init.lua, and
# replaces the pane you came from with a shell in the chosen project.

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  printf 'Usage: %s SESSION_ID BLOCK_ID\n' "$0" >&2
  exit 2
fi

readonly target_session="$1"
readonly target_block="$2"
preview="$(dirname "$0")/../tmux/project-preview.sh"
readonly preview

# Catppuccin Mocha, with a transparent background to match Neovim's picker.
colors=(
  'bg:-1,bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4'
  'hl:#f38ba8,hl+:#f38ba8,info:#cba6f7,marker:#b4befe'
  'prompt:#cba6f7,pointer:#f5e0dc,spinner:#f5e0dc,header:#f38ba8'
  'border:#6c7086,label:#cdd6f4,preview-border:#6c7086'
  'preview-label:#cdd6f4,separator:#45475a,scrollbar:#585b70'
  'query:#cdd6f4,gutter:-1'
)

# Home directories pinned to the top of the list. Add more here.
pinned=(
  "${HOME}/.dotfiles"
  "${HOME}/.ssh"
)

selection="$({
  for dir in "${pinned[@]}"; do
    [[ -d "${dir}" ]] && printf '%s\n' "${dir}"
  done
  fd --type d --max-depth 3 --hidden \
    --exclude .git --exclude node_modules \
    . "${HOME}/Developer" "${HOME}/Projects" 2>/dev/null
  fd --type d --min-depth 2 --max-depth 2 --hidden \
    --exclude .git --exclude node_modules \
    . "${HOME}/Work" 2>/dev/null
} | sed -e "s|^${HOME}|~|" -e 's|/$||' | fzf \
  --ansi \
  --layout=reverse \
  --border=rounded \
  --border-label=' 󰉋 Projects ' \
  --border-label-pos=3 \
  --prompt='  ' \
  --pointer='▌' \
  --marker='┃' \
  --gutter=' ' \
  --info=inline-right \
  --separator='─' \
  --scrollbar='│' \
  --padding=0,1 \
  --preview="'${preview}' {}" \
  --preview-window='right,60%,border-rounded,<90(down,55%,border-rounded)' \
  --preview-label=' Preview ' \
  --bind='ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
  --bind='ctrl-/:toggle-preview' \
  --color="$(IFS=,; printf '%s' "${colors[*]}")"
)" || true

if [[ -z "${selection}" ]]; then
  rex focus -s "${target_session}" "${target_block}" >/dev/null
  exit 0
fi
project="${selection/#\~/${HOME}}"

# Like tmux respawn-pane: split the original pane, then close it, so the new
# shell takes its exact slot.
if ! rex split -s "${target_session}" -b "${target_block}" -c "${project}" --json >/dev/null; then
  printf '\nCould not open %s in the current pane.\n\nPress any key to close.' "${project}" >&2
  read -rsn1
  exit 1
fi
rex block close -s "${target_session}" "${target_block}"
