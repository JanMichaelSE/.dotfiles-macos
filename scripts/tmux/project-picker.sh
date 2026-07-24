#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 0 ]]; then
  printf 'Usage: %s\n' "$0" >&2
  exit 2
fi

target_pane="$(tmux display-message -p '#{pane_id}')"
readonly target_pane

project="$({
  fd --type d --max-depth 3 --hidden \
    --exclude .git --exclude node_modules \
    . "${HOME}/Developer" "${HOME}/Projects" 2>/dev/null
  fd --type d --min-depth 2 --max-depth 2 --hidden \
    --exclude .git --exclude node_modules \
    . "${HOME}/Work" 2>/dev/null
} | fzf)" || exit 0

[[ -n "${project}" ]] || exit 0

tmux respawn-pane -k -t "${target_pane}" -c "${project}"
