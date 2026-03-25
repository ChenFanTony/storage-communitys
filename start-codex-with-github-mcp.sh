#!/usr/bin/env bash
set -euo pipefail

# Prefer an already-exported token. Otherwise, derive one from gh auth.
if [ -z "${GITHUB_PAT_TOKEN:-}" ]; then
  if command -v gh >/dev/null 2>&1; then
    export GITHUB_PAT_TOKEN="$(gh auth token)"
  else
    echo "GITHUB_PAT_TOKEN is not set and gh is unavailable." >&2
    echo "Export GITHUB_PAT_TOKEN before launching Codex." >&2
    exit 1
  fi
fi

exec codex "$@"
