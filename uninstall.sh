#!/usr/bin/env bash
set -e

CVM_DIR="${CVM_DIR:-$HOME/.cvm}"
CVM_PROFILE_BLOCK_START="# >>> cvm initialize >>>"
CVM_PROFILE_BLOCK_END="# <<< cvm initialize <<<"

cvm_uninstall_has() {
  command -v "$1" >/dev/null 2>&1
}

cvm_uninstall_detect_shell_profile() {
  case "${SHELL##*/}" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      return 0
      ;;
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        printf '%s\n' "$HOME/.bashrc"
      else
        printf '%s\n' "$HOME/.bash_profile"
      fi
      return 0
      ;;
  esac

  if [ -f "$HOME/.zshrc" ]; then
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

  printf '%s\n' "$HOME/.profile"
}

cvm_uninstall_detect_profile() {
  if [ -n "${PROFILE-}" ] && [ -f "$PROFILE" ]; then
    printf '%s\n' "$PROFILE"
    return 0
  fi

  cvm_uninstall_detect_shell_profile
}

cvm_uninstall_cleanup_profile() {
  local profile_file temp_file

  profile_file="$1"
  [ -f "$profile_file" ] || return 0

  temp_file="$(mktemp "${TMPDIR:-/tmp}/cvm-profile.XXXXXX")"

  awk -v start="$CVM_PROFILE_BLOCK_START" -v end="$CVM_PROFILE_BLOCK_END" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$profile_file" >"$temp_file"

  mv "$temp_file" "$profile_file"

  if cvm_uninstall_has perl; then
    perl -0pi -e 's/\n{3,}/\n\n/g; s/\A\n+//; s/\n+\z/\n/' "$profile_file"
  fi

  if cvm_uninstall_has grep; then
    if grep -Fq "$CVM_DIR/cvm.sh" "$profile_file" || grep -Fq "$CVM_DIR/bash_completion" "$profile_file"; then
      temp_file="$(mktemp "${TMPDIR:-/tmp}/cvm-profile.XXXXXX")"
      grep -Fv "$CVM_DIR/cvm.sh" "$profile_file" | \
        grep -Fv "$CVM_DIR/bash_completion" | \
        grep -Fv 'export CVM_DIR="$HOME/.cvm"' >"$temp_file" || true
      mv "$temp_file" "$profile_file"
    fi
  fi
}

PROFILE_FILE="$(cvm_uninstall_detect_profile)"

cvm_uninstall_cleanup_profile "$PROFILE_FILE"
rm -rf "$CVM_DIR"

printf '%s\n' "cvm has been removed from $PROFILE_FILE"
printf '%s\n' "Removed $CVM_DIR"
printf '%s\n' "Restart your shell or source $PROFILE_FILE"
