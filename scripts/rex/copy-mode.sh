#!/usr/bin/env bash
# Rex stand-in for tmux copy mode. Runs inside a floating Rex pane opened by
# the `copy_mode` action in ~/.config/rex/init.lua, and opens the scrollback of
# the pane you came from in Neovim, at the bottom, like tmux's <prefix> [.
#
#   v / V / ctrl-v  select     y  copy to the system clipboard     q  close

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  printf 'Usage: %s SESSION_ID BLOCK_ID\n' "$0" >&2
  exit 2
fi

scrollback="$(mktemp "${TMPDIR:-/tmp}/rex-copy-mode.XXXXXX")"
readonly scrollback
trap 'rm -f "${scrollback}"' EXIT

rex capture -s "$1" -b "$2" --trim --unwrap >"${scrollback}"

nvim -R + \
  -c 'setlocal nomodifiable nomodified clipboard=unnamedplus' \
  -c 'nnoremap <buffer> <nowait> q <cmd>qa!<cr>' \
  "${scrollback}"

# Hand focus back to the pane we copied from before this popup closes.
rex focus -s "$1" "$2" >/dev/null
