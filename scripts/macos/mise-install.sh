#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly DOTFILES_DIR
readonly MISE_BIN="${MISE_BIN:-/opt/homebrew/bin/mise}"
readonly MISE_CONFIG="${DOTFILES_DIR}/config/mise/config.toml"

if [[ ! -x "${MISE_BIN}" ]]; then
  printf 'Error: mise is not installed. Run the Homebrew bundle step first.\n' >&2
  exit 1
fi

if [[ ! -f "${MISE_CONFIG}" ]]; then
  printf 'Error: mise config is missing at %s.\n' "${MISE_CONFIG}" >&2
  exit 1
fi

export MISE_GLOBAL_CONFIG_FILE="${MISE_CONFIG}"
export MISE_GLOBAL_CONFIG_ROOT="${HOME}"

tool_names="$({
  awk '
    /^[[:space:]]*\[tools\][[:space:]]*(#.*)?$/ {
      in_tools = 1
      next
    }

    in_tools && /^[[:space:]]*\[/ {
      exit
    }

    in_tools && !/^[[:space:]]*(#|$)/ {
      equals = index($0, "=")
      if (equals == 0) {
        next
      }

      key = substr($0, 1, equals - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)

      if ((substr(key, 1, 1) == "\"" && substr(key, length(key), 1) == "\"") ||
          (substr(key, 1, 1) == "\047" && substr(key, length(key), 1) == "\047")) {
        key = substr(key, 2, length(key) - 2)
      }

      if (key != "") {
        print key
      }
    }
  ' "${MISE_CONFIG}"
})" || {
  printf 'Error: unable to read tools from %s.\n' "${MISE_CONFIG}" >&2
  exit 1
}

core_tools=()
npm_tools=()
has_node=false

while IFS= read -r tool_name; do
  [[ -n "${tool_name}" ]] || continue

  case "${tool_name}" in
    npm:*)
      npm_tools[${#npm_tools[@]}]="${tool_name}"
      ;;
    *)
      core_tools[${#core_tools[@]}]="${tool_name}"
      [[ "${tool_name}" == "node" ]] && has_node=true
      ;;
  esac
done <<EOF
${tool_names}
EOF

if [[ ${#core_tools[@]} -eq 0 ]]; then
  printf 'Error: no core tools are declared in %s.\n' "${MISE_CONFIG}" >&2
  exit 1
fi

printf 'Installing core runtimes and tools from %s.\n' "${MISE_CONFIG}"
"${MISE_BIN}" install "${core_tools[@]}"

if [[ ${#npm_tools[@]} -gt 0 ]]; then
  if [[ "${has_node}" != true ]]; then
    printf 'Error: npm tools are declared, but node is not declared in %s.\n' \
      "${MISE_CONFIG}" >&2
    exit 1
  fi

  node_install_dir="$("${MISE_BIN}" where node)"
  if [[ ! -x "${node_install_dir}/bin/npm" ]]; then
    printf 'Error: npm is unavailable after installing the configured Node.js runtime.\n' >&2
    exit 1
  fi

  printf 'Installing npm-backed tools after Node.js is ready.\n'
  "${MISE_BIN}" install "${npm_tools[@]}"
fi

"${MISE_BIN}" reshim

printf 'mise tools are installed from %s.\n' "${MISE_CONFIG}"
