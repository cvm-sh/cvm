#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env

help_output="$(cvm help)"
assert_contains "$help_output" "Claude Version Manager"
assert_contains "$help_output" "cvm ls-remote [prefix]"

assert_eq "system" "$(cvm current)"

ls_output="$(cvm ls)"
assert_contains "$ls_output" "-> system"

install_fake_claude "2.1.132"
ls_output="$(cvm ls)"
assert_contains "$ls_output" "2.1.132"
