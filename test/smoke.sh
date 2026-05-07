#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export CVM_DIR="$ROOT_DIR/.tmp/cvm"
. "$ROOT_DIR/cvm.sh"

cvm help >/dev/null
cvm cache dir >/dev/null
cvm current >/dev/null
cvm ls >/dev/null

mkdir -p "$CVM_DIR/versions/2.1.132/bin"
cat >"$CVM_DIR/versions/2.1.132/bin/claude" <<'EOF'
#!/usr/bin/env bash
echo "2.1.132 (Claude Code)"
EOF
chmod +x "$CVM_DIR/versions/2.1.132/bin/claude"

ORIGINAL_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
PATH="$ORIGINAL_PATH"
export PATH

cvm use 2.1.132 >/dev/null
[ "$(command -v claude)" = "$CVM_DIR/versions/2.1.132/bin/claude" ]

cvm use system >/dev/null
[ "$PATH" = "$ORIGINAL_PATH" ]

if command -v zsh >/dev/null 2>&1; then
  zsh -lc "
    export CVM_DIR='$CVM_DIR-zsh'
    . '$ROOT_DIR/cvm.sh'
    mkdir -p \"\$CVM_DIR/versions/2.1.132/bin\"
    cat >\"\$CVM_DIR/versions/2.1.132/bin/claude\" <<'INNER'
#!/usr/bin/env bash
echo '2.1.132 (Claude Code)'
INNER
    chmod +x \"\$CVM_DIR/versions/2.1.132/bin/claude\"
    export PATH='/usr/bin:/bin:/usr/sbin:/sbin'
    cvm use 2.1.132 >/dev/null
    cvm use system >/dev/null
    command -v mkdir >/dev/null
    command -v find >/dev/null
    command -v sort >/dev/null
  "
fi

printf '%s\n' 'smoke ok'
