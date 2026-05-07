#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env
install_fake_claude "2.1.132"
make_fake_system_claude

assert_eq "$CVM_DIR/versions/2.1.132/bin/claude" "$(cvm which 2.1.132)"
assert_contains "$(cvm run 2.1.132 --version)" "2.1.132"
assert_contains "$(cvm exec 2.1.132 claude --version)" "2.1.132"
assert_eq "$TEST_HOME/system/bin/claude" "$(cvm which system)"

set +e
cvm exec >/dev/null 2>&1
status=$?
set -e
assert_status_nonzero "$status"
