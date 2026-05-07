#!/usr/bin/env bash
set -e

CVM_INSTALL_VERSION="${CVM_INSTALL_VERSION:-main}"
CVM_INSTALL_GITHUB_REPO="${CVM_INSTALL_GITHUB_REPO:-cvm-sh/cvm}"

cvm_install_has() {
  command -v "$1" >/dev/null 2>&1
}

cvm_install_fetch() {
  local path
  local url

  path="$1"
  url="https://raw.githubusercontent.com/$CVM_INSTALL_GITHUB_REPO/$CVM_INSTALL_VERSION/$path"

  if cvm_install_has curl; then
    curl -fsSL "$url"
    return $?
  fi

  if cvm_install_has wget; then
    wget -qO- "$url"
    return $?
  fi

  printf '%s\n' "cvm installer requires curl or wget." >&2
  return 1
}

cvm_detect_shell_profile() {
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

cvm_detect_profile() {
  if [ -n "${PROFILE-}" ] && [ -f "$PROFILE" ]; then
    printf '%s\n' "$PROFILE"
    return 0
  fi

  cvm_detect_shell_profile
}

PROFILE_FILE="$(cvm_detect_profile)"

mkdir -p "$HOME/.cvm"
touch "$PROFILE_FILE"

CVM_SH_DEST="$HOME/.cvm/cvm.sh"
CVM_COMPLETION_DEST="$HOME/.cvm/bash_completion"
CVM_LIB_DIR="$HOME/.cvm/lib"
CVM_VERSION_FILTER_DEST="$CVM_LIB_DIR/version-filter.js"

mkdir -p "$CVM_LIB_DIR"

if [ -f "$(cd "$(dirname "$0")" && pwd)/cvm.sh" ]; then
  SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
  cp "$SOURCE_DIR/cvm.sh" "$CVM_SH_DEST"
  cp "$SOURCE_DIR/bash_completion" "$CVM_COMPLETION_DEST"
  cp "$SOURCE_DIR/lib/version-filter.js" "$CVM_VERSION_FILTER_DEST"
else
  cvm_install_fetch "cvm.sh" >"$CVM_SH_DEST"
  cvm_install_fetch "bash_completion" >"$CVM_COMPLETION_DEST"
  cvm_install_fetch "lib/version-filter.js" >"$CVM_VERSION_FILTER_DEST"
fi

if ! grep -Fq "$CVM_SH_DEST" "$PROFILE_FILE"; then
  cat >>"$PROFILE_FILE" <<EOF

export CVM_DIR="\$HOME/.cvm"
[ -s "$CVM_SH_DEST" ] && \. "$CVM_SH_DEST"
[ -s "$CVM_COMPLETION_DEST" ] && \. "$CVM_COMPLETION_DEST"
EOF
fi

printf '%s\n' "cvm has been added to $PROFILE_FILE"
printf '%s\n' "Run: source $PROFILE_FILE"
