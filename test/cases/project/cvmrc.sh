#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env
install_fake_claude "2.1.132"
install_fake_claude "2.1.130"

project_dir="$TEST_HOME/project"
sub_dir="$project_dir/subdir"
mkdir -p "$sub_dir"
printf '%s\n' "2.1.132" >"$project_dir/.cvmrc"

(
  cd "$sub_dir"
  cvm use >/dev/null
  assert_eq "2.1.132" "$CVM_CURRENT_VERSION"
)

rm -f "$project_dir/.cvmrc"
cvm alias default 2.1.130 >/dev/null
(
  cd "$sub_dir"
  cvm use >/dev/null
  assert_eq "2.1.130" "$CVM_CURRENT_VERSION"
)
