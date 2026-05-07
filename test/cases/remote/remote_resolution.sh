#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env
stub_remote_versions
cvm_node_json_filter() {
  case "${1-}" in
    latest|'')
      printf '%s\n' "2.1.130" "2.1.132" "2.2.0" "3.0.0-beta.1"
      ;;
    2.1)
      printf '%s\n' "2.1.130" "2.1.132"
      ;;
    2.2)
      printf '%s\n' "2.2.0"
      ;;
    *)
      ;;
  esac
}

assert_contains "$(cvm ls-remote)" "2.1.132"
assert_eq "2.1.132" "$(cvm version-remote 2.1)"
assert_eq "3.0.0-beta.1" "$(cvm version-remote latest)"

install_fake_claude "2.1.130"
install_fake_claude "2.1.132"
assert_eq "2.1.132" "$(cvm version 2.1)"

set +e
output="$(cvm version 9.9 2>/dev/null)"
status=$?
set -e
assert_eq "N/A" "$output"
assert_status_nonzero "$status"
