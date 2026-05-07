#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
count=0

while IFS= read -r test_file; do
  count=$((count + 1))
  printf '%s\n' "==> $test_file"
  bash "$test_file"
done < <(find "$ROOT_DIR/cases" -type f -name '*.sh' | sort)

printf '%s\n' "ok: $count tests"
