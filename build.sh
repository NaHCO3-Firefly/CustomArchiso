#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo rm -rf /tmp/archiso-tmp
sudo mkarchiso -v -w /tmp/archiso-tmp "$SCRIPT_DIR"
exec "$SCRIPT_DIR/test.sh"
