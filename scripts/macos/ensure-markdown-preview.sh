#!/usr/bin/env bash

set -euo pipefail

readonly MARKDOWN_PREVIEW_APP_DIR="${MARKDOWN_PREVIEW_APP_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/lazy/markdown-preview.nvim/app}"

if [[ ! -f "${MARKDOWN_PREVIEW_APP_DIR}/package.json" ]]; then
  printf 'Error: markdown-preview.nvim is not installed at %s.\n' \
    "${MARKDOWN_PREVIEW_APP_DIR}" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  printf 'Error: Node.js and npm are required for markdown-preview.nvim.\n' >&2
  exit 1
fi

dependencies_are_available() {
  (
    cd "${MARKDOWN_PREVIEW_APP_DIR}"
    node -e '
      const dependencies = Object.keys(require("./package.json").dependencies || {});
      for (const dependency of dependencies) require.resolve(dependency);
    '
  ) >/dev/null 2>&1
}

if ! dependencies_are_available; then
  printf 'Installing markdown-preview.nvim Node.js dependencies.\n'
  npm --prefix "${MARKDOWN_PREVIEW_APP_DIR}" install --no-package-lock
fi

if ! dependencies_are_available; then
  printf 'Error: markdown-preview.nvim dependencies are still incomplete.\n' >&2
  exit 1
fi

printf 'markdown-preview.nvim Node.js dependencies are ready.\n'