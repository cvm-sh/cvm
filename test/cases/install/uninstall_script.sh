#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

test_home="$(new_test_home)"
export HOME="$test_home/home"
mkdir -p "$HOME"
export SHELL="/bin/zsh"
export CVM_DIR="$HOME/.cvm"

bash "$REPO_ROOT/install.sh" >/dev/null

assert_file_exists "$HOME/.cvm/cvm.sh"
assert_file_exists "$HOME/.zshrc"
profile_contents="$(cat "$HOME/.zshrc")"
assert_contains "$profile_contents" "# >>> cvm initialize >>>"

bash "$REPO_ROOT/uninstall.sh" >/dev/null

[ ! -d "$HOME/.cvm" ] || fail "expected ~/.cvm to be removed"
profile_contents="$(cat "$HOME/.zshrc")"
case "$profile_contents" in
  *"cvm.sh"*|*"bash_completion"*|*"export CVM_DIR"*|*"# >>> cvm initialize >>>"*)
    fail "expected cvm profile entries to be removed"
    ;;
esac

bash "$REPO_ROOT/uninstall.sh" >/dev/null
