#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "$0")/../.." && pwd)/lib/helpers.sh"

setup_cvm_env
install_fake_claude "2.1.132"
make_fake_system_claude

original_path="$PATH"
cvm use 2.1.132 >/dev/null
assert_eq "$CVM_DIR/versions/2.1.132/bin/claude" "$(command -v claude)"
assert_eq "2.1.132" "$(cvm current)"

cvm use system >/dev/null
assert_eq "$original_path" "$PATH"
assert_eq "system" "$(cvm current)"
command -v mkdir >/dev/null
command -v find >/dev/null
command -v sort >/dev/null

if command -v zsh >/dev/null 2>&1; then
  zsh -lc "
    export HOME='$HOME'
    export CVM_DIR='$CVM_DIR-zsh'
    export CVM_SCRIPT_DIR='$REPO_ROOT'
    export PATH='$original_path'
    . '$REPO_ROOT/cvm.sh'
    mkdir -p \"\$CVM_DIR/versions/2.1.132/bin\"
    cat >\"\$CVM_DIR/versions/2.1.132/bin/claude\" <<'EOF'
#!/usr/bin/env bash
echo '2.1.132 (Claude Code)'
EOF
    chmod +x \"\$CVM_DIR/versions/2.1.132/bin/claude\"
    cvm use 2.1.132 >/dev/null
    cvm use system >/dev/null
    command -v mkdir >/dev/null
    command -v find >/dev/null
    command -v sort >/dev/null
  "
fi
