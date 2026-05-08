#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

test_home="$(new_test_home)"
export HOME="$test_home/home"
mkdir -p "$HOME"
export SHELL="/bin/zsh"
export CVM_DIR="$HOME/.cvm"
export CVM_INSTALL_GITHUB_REPO="cvm-sh/cvm"
export CVM_INSTALL_VERSION="main"

bash "$REPO_ROOT/install.sh" >/dev/null

assert_file_exists "$HOME/.cvm/cvm.sh"
assert_file_exists "$HOME/.cvm/bash_completion"
assert_file_exists "$HOME/.cvm/lib/version-filter.js"
assert_file_exists "$HOME/.zshrc"

profile_contents="$(cat "$HOME/.zshrc")"
assert_contains "$profile_contents" 'export CVM_DIR="$HOME/.cvm"'
assert_contains "$profile_contents" "$HOME/.cvm/cvm.sh" "expected installer to source ~/.cvm/cvm.sh"

bash "$REPO_ROOT/install.sh" >/dev/null
profile_contents="$(cat "$HOME/.zshrc")"
count="$(printf '%s' "$profile_contents" | grep -c "$HOME/.cvm/cvm.sh" || true)"
assert_eq "1" "$count" "expected installer to be idempotent"
