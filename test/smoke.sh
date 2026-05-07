#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export CVM_DIR="$ROOT_DIR/.tmp/cvm"
. "$ROOT_DIR/cvm.sh"

cvm help >/dev/null
cvm cache dir >/dev/null
cvm current >/dev/null
cvm ls >/dev/null

printf '%s\n' 'smoke ok'
