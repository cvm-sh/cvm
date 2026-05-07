#!/usr/bin/env bash
set -e

cvm_detect_profile() {
  if [ -n "${PROFILE-}" ] && [ -f "$PROFILE" ]; then
    printf '%s\n' "$PROFILE"
    return 0
  fi

  if [ -n "${ZSH_VERSION-}" ] && [ -f "$HOME/.zshrc" ]; then
    printf '%s\n' "$HOME/.zshrc"
    return 0
  fi

  if [ -f "$HOME/.bashrc" ]; then
    printf '%s\n' "$HOME/.bashrc"
    return 0
  fi

  if [ -f "$HOME/.bash_profile" ]; then
    printf '%s\n' "$HOME/.bash_profile"
    return 0
  fi

  if [ -f "$HOME/.profile" ]; then
    printf '%s\n' "$HOME/.profile"
    return 0
  fi

  printf '%s\n' "$HOME/.zshrc"
}

PROFILE_FILE="$(cvm_detect_profile)"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.cvm"
touch "$PROFILE_FILE"

if ! grep -Fq "$SOURCE_DIR/cvm.sh" "$PROFILE_FILE"; then
  cat >>"$PROFILE_FILE" <<EOF

export CVM_DIR="\$HOME/.cvm"
[ -s "$SOURCE_DIR/cvm.sh" ] && \. "$SOURCE_DIR/cvm.sh"
[ -s "$SOURCE_DIR/bash_completion" ] && \. "$SOURCE_DIR/bash_completion"
EOF
fi

printf '%s\n' "cvm has been added to $PROFILE_FILE"
printf '%s\n' "Run: source $PROFILE_FILE"
