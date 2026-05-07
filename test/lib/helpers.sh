#!/usr/bin/env bash

set -euo pipefail

TEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(cd "$TEST_LIB_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TEST_ROOT/.." && pwd)"

fail() {
  printf '%s\n' "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected actual message
  expected="$1"
  actual="$2"
  message="${3:-expected '$expected', got '$actual'}"
  [ "$expected" = "$actual" ] || fail "$message"
}

assert_contains() {
  local haystack needle message
  haystack="$1"
  needle="$2"
  message="${3:-expected output to contain '$needle'}"
  case "$haystack" in
    *"$needle"*)
      ;;
    *)
      fail "$message"
      ;;
  esac
}

assert_file_exists() {
  [ -f "$1" ] || fail "expected file to exist: $1"
}

assert_dir_missing() {
  [ ! -d "$1" ] || fail "expected directory to be missing: $1"
}

assert_status_nonzero() {
  local status
  status="$1"
  [ "$status" -ne 0 ] || fail "expected non-zero status"
}

new_test_home() {
  mktemp -d "${TMPDIR:-/tmp}/cvm-test.XXXXXX"
}

setup_cvm_env() {
  TEST_HOME="$(new_test_home)"
  export HOME="$TEST_HOME/home"
  mkdir -p "$HOME"
  export CVM_DIR="$TEST_HOME/.cvm"
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
  export CVM_SCRIPT_DIR="$REPO_ROOT"
  . "$REPO_ROOT/cvm.sh"
}

install_fake_claude() {
  local version version_dir
  version="$1"
  version_dir="$CVM_DIR/versions/$version/bin"
  mkdir -p "$version_dir"
  cat >"$version_dir/claude" <<EOF
#!/usr/bin/env bash
echo "$version (Claude Code)"
EOF
  chmod +x "$version_dir/claude"
}

stub_remote_versions() {
  cvm_remote_versions() {
    cat <<'EOF'
["2.1.130","2.1.132","2.2.0","3.0.0-beta.1"]
EOF
  }
}

make_fake_system_claude() {
  local system_dir
  system_dir="$TEST_HOME/system/bin"
  mkdir -p "$system_dir"
  cat >"$system_dir/claude" <<'EOF'
#!/usr/bin/env bash
echo "system-1.0.0 (Claude Code)"
EOF
  chmod +x "$system_dir/claude"
  export PATH="$system_dir:/usr/bin:/bin:/usr/sbin:/sbin"
}
