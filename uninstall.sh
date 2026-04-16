#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
  echo "[ERROR] install.sh not found: $INSTALL_SCRIPT" >&2
  exit 1
fi

exec "$INSTALL_SCRIPT" --uninstall