#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env
install_fake_claude "2.1.132"
stub_remote_versions

create_output="$(cvm alias default 2.1.132)"
assert_contains "$create_output" "default -> 2.1.132"
assert_eq "2.1.132" "$(cvm alias default)"
assert_contains "$(cvm alias)" "default -> 2.1.132"

cvm use default >/dev/null
assert_eq "2.1.132" "$(cvm current)"

delete_output="$(cvm unalias default)"
assert_contains "$delete_output" "Deleted alias default"

set +e
cvm unalias default >/dev/null 2>&1
status=$?
set -e
assert_status_nonzero "$status"
