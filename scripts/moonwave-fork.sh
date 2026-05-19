#!/usr/bin/env bash
# moonwave-fork.sh
#
# Set up and run Moonwave using the iamnoderbx fork's plugin (which adds
# nested-folder support to `autoSectionPath`) without publishing to npm.
#
# Usage:
#   ./moonwave-fork.sh setup              Clone or update the fork only
#   ./moonwave-fork.sh dev                Run `moonwave dev`  with the fork
#   ./moonwave-fork.sh build              Run `moonwave build` with the fork
#   ./moonwave-fork.sh <any other args>   Pass args straight to `moonwave`
#
# Requirements: git, node (>=18), npm, and the upstream Moonwave CLI
# (install with: npm install -g moonwave).
#
# Environment overrides:
#   MOONWAVE_FORK_REPO     Defaults to https://github.com/iamnoderbx/moonwave.git
#   MOONWAVE_FORK_BRANCH   Defaults to master
#   MOONWAVE_FORK_DIR      Where to clone the fork; defaults to .moonwave-fork

set -euo pipefail

FORK_REPO="${MOONWAVE_FORK_REPO:-https://github.com/iamnoderbx/moonwave.git}"
FORK_BRANCH="${MOONWAVE_FORK_BRANCH:-master}"
FORK_DIR="${MOONWAVE_FORK_DIR:-.moonwave-fork}"
PLUGIN_REL="docusaurus-plugin-moonwave"

log()  { printf '[moonwave-fork] %s\n' "$*"; }
err()  { printf '[moonwave-fork] error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1 || err "missing required command: $1"; }

setup() {
  have git
  have npm

  if [ -d "$FORK_DIR/.git" ]; then
    log "Updating fork in $FORK_DIR"
    git -C "$FORK_DIR" fetch --depth=1 origin "$FORK_BRANCH"
    git -C "$FORK_DIR" reset --hard "origin/$FORK_BRANCH"
  else
    log "Cloning $FORK_REPO ($FORK_BRANCH) into $FORK_DIR"
    git clone --depth=1 --branch "$FORK_BRANCH" "$FORK_REPO" "$FORK_DIR"
  fi

  if [ ! -d "$FORK_DIR/$PLUGIN_REL/node_modules" ]; then
    log "Installing plugin dependencies"
    (cd "$FORK_DIR/$PLUGIN_REL" && npm install --silent)
  fi

  log "Fork ready at $FORK_DIR/$PLUGIN_REL"
}

run() {
  command -v moonwave >/dev/null 2>&1 \
    || err "global moonwave CLI not found; install it with: npm install -g moonwave"

  setup

  local plugin_abs
  plugin_abs="$(cd "$FORK_DIR/$PLUGIN_REL" && pwd)"

  log "MOONWAVE_PLUGIN_PATH=$plugin_abs"
  MOONWAVE_PLUGIN_PATH="$plugin_abs" exec moonwave "$@"
}

case "${1:-dev}" in
  setup)
    setup
    ;;
  *)
    run "$@"
    ;;
esac
