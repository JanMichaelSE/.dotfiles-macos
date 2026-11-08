#!/usr/bin/env bash
# Preview a project directory for the tmux project picker.
# Shows git branch/status and a shallow tree.

set -uo pipefail

dir="${1/#\~/${HOME}}"
[[ -d "${dir}" ]] || exit 0

# Catppuccin Mocha accents.
mauve=$'\e[38;2;203;166;247m'
green=$'\e[38;2;166;227;161m'
peach=$'\e[38;2;250;179;135m'
overlay=$'\e[38;2;108;112;134m'
reset=$'\e[0m'

if git -C "${dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "${dir}" branch --show-current 2>/dev/null)"
  changes="$(git -C "${dir}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  last="$(git -C "${dir}" log -1 --format='%cr · %s' 2>/dev/null)"
  printf '%s %s%s' "${mauve}" "${branch:-detached}" "${reset}"
  if [[ "${changes}" -gt 0 ]]; then
    printf '  %s● %s changed%s' "${peach}" "${changes}" "${reset}"
  else
    printf '  %s✓ clean%s' "${green}" "${reset}"
  fi
  [[ -n "${last}" ]] && printf '\n%s%s%s' "${overlay}" "${last}" "${reset}"
  printf '\n\n'
fi

eza --tree --level=2 --icons=always --color=always --group-directories-first \
  --git-ignore --ignore-glob='.git|node_modules' "${dir}" 2>/dev/null
