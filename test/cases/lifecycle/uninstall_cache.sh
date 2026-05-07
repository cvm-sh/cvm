#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env
install_fake_claude "2.1.132"

cvm use 2.1.132 >/dev/null
cvm uninstall 2.1.132 >/dev/null
assert_eq "system" "$(cvm current)"
assert_dir_missing "$CVM_DIR/versions/2.1.132"

cache_dir="$(cvm cache dir)"
assert_eq "$CVM_DIR/.cache" "$cache_dir"
mkdir -p "$cache_dir/example"
cvm cache clear >/dev/null
[ -d "$cache_dir" ] || fail "expected cache dir to be recreated"
