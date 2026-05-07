#!/usr/bin/env bash

if [ -z "${CVM_DIR-}" ]; then
  export CVM_DIR="$HOME/.cvm"
fi

CVM_PACKAGE_NAME='@anthropic-ai/claude-code'
CVM_SCRIPT_DIR="${CVM_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

cvm() {
  local command
  command="${1-}"

  if [ $# -gt 0 ]; then
    shift
  fi

  case "$command" in
    ''|-h|--help|help)
      cvm_help
      ;;
    install)
      cvm_install "$@"
      ;;
    uninstall)
      cvm_uninstall "$@"
      ;;
    use)
      cvm_use "$@"
      ;;
    deactivate)
      cvm_deactivate
      ;;
    unload)
      cvm_unload
      ;;
    current)
      cvm_current
      ;;
    ls|list)
      cvm_ls
      ;;
    ls-remote|list-remote)
      cvm_ls_remote "$@"
      ;;
    version)
      cvm_version "$@"
      ;;
    version-remote)
      cvm_version_remote "$@"
      ;;
    which)
      cvm_which "$@"
      ;;
    run)
      cvm_run "$@"
      ;;
    exec)
      cvm_exec "$@"
      ;;
    alias)
      cvm_alias "$@"
      ;;
    unalias)
      cvm_unalias "$@"
      ;;
    cache)
      cvm_cache "$@"
      ;;
    *)
      cvm_err "Unknown command: $command"
      cvm_help
      return 127
      ;;
  esac
}

cvm_help() {
  cat <<'EOF'

Claude Version Manager (cvm)

Usage:
  cvm install <version|latest|.cvmrc>
  cvm uninstall <version>
  cvm use <version|default|system>
  cvm deactivate
  cvm unload
  cvm current
  cvm ls
  cvm ls-remote [prefix]
  cvm version <version>
  cvm version-remote <version|latest>
  cvm which <version>
  cvm run <version> [claude args...]
  cvm exec <version> <command> [args...]
  cvm alias [name] [target]
  cvm unalias <name>
  cvm cache dir|clear

Examples:
  cvm install latest
  cvm install 1.0
  cvm use 1.0.117
  cvm alias default 1.0.117
  cvm run 1.0.117 --version
  cvm exec 1.0.117 claude doctor

Storage:
  Versions: $CVM_DIR/versions/<version>
  Aliases:  $CVM_DIR/alias/<name>
EOF
}

cvm_err() {
  printf '%s\n' "$*" >&2
}

cvm_has() {
  command -v "$1" >/dev/null 2>&1
}

cvm_ensure_dirs() {
  mkdir -p "$(cvm_versions_dir)" "$(cvm_alias_dir)" "$(cvm_cache_dir)"
}

cvm_versions_dir() {
  printf '%s\n' "$CVM_DIR/versions"
}

cvm_alias_dir() {
  printf '%s\n' "$CVM_DIR/alias"
}

cvm_cache_dir() {
  printf '%s\n' "$CVM_DIR/.cache"
}

cvm_strip_path() {
  local entry
  local new_path
  local old_ifs

  new_path=''
  old_ifs=$IFS
  IFS=':'

  for entry in $PATH; do
    case "$entry" in
      "$CVM_DIR"/versions/*/bin|"$CVM_DIR"/current/bin)
        ;;
      *)
        if [ -n "$entry" ]; then
          if [ -n "$new_path" ]; then
            new_path="${new_path}:$entry"
          else
            new_path="$entry"
          fi
        fi
        ;;
    esac
  done

  IFS=$old_ifs
  printf '%s\n' "$new_path"
}

cvm_find_rc_file() {
  local dir

  dir="${PWD}"
  while [ "$dir" != '/' ]; do
    if [ -f "$dir/.cvmrc" ]; then
      printf '%s\n' "$dir/.cvmrc"
      return 0
    fi
    dir=$(dirname "$dir")
  done

  if [ -f '/.cvmrc' ]; then
    printf '%s\n' '/.cvmrc'
    return 0
  fi

  return 1
}

cvm_read_rc() {
  local rc_file

  rc_file="$(cvm_find_rc_file)" || return 1
  sed -n '1{s/[[:space:]]*$//;p;}' "$rc_file"
}

cvm_alias_path() {
  printf '%s\n' "$(cvm_alias_dir)/$1"
}

cvm_alias_target() {
  local path

  path="$(cvm_alias_path "$1")"
  if [ -f "$path" ]; then
    sed -n '1{s/[[:space:]]*$//;p;}' "$path"
    return 0
  fi

  return 1
}

cvm_is_exact_version() {
  case "$1" in
    [0-9]*.[0-9]*.[0-9]*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

cvm_node_json_filter() {
  local filter

  if ! cvm_has node; then
    cvm_err 'node is required to resolve Claude Code versions.'
    return 1
  fi

  filter="${1-}"
  FILTER="$filter" node "$CVM_SCRIPT_DIR/lib/version-filter.js"
}

cvm_local_versions() {
  cvm_ensure_dirs
  find "$(cvm_versions_dir)" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

cvm_remote_versions() {
  if ! cvm_has npm; then
    cvm_err 'npm is required to query Claude Code versions.'
    return 1
  fi

  npm view "$CVM_PACKAGE_NAME" versions --json 2>/dev/null
}

cvm_pick_local_version() {
  local requested
  local resolved

  requested="$1"

  if [ "$requested" = 'current' ]; then
    if [ -n "${CVM_CURRENT_VERSION-}" ]; then
      printf '%s\n' "$CVM_CURRENT_VERSION"
      return 0
    fi
    return 1
  fi

  if [ "$requested" = 'default' ]; then
    requested="$(cvm_alias_target default)" || return 1
  fi

  if [ "$requested" = '.cvmrc' ] || [ -z "$requested" ]; then
    requested="$(cvm_read_rc)" || requested="$(cvm_alias_target default 2>/dev/null || true)"
    [ -n "$requested" ] || return 1
  fi

  if [ "$requested" = 'system' ]; then
    printf '%s\n' 'system'
    return 0
  fi

  resolved="$(cvm_alias_target "$requested" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    requested="$resolved"
  fi

  if [ -d "$(cvm_versions_dir)/$requested" ]; then
    printf '%s\n' "$requested"
    return 0
  fi

  resolved="$(cvm_local_versions | cvm_node_json_filter "$requested" | tail -n 1)"
  if [ -n "$resolved" ]; then
    printf '%s\n' "$resolved"
    return 0
  fi

  return 1
}

cvm_pick_remote_version() {
  local requested
  local resolved
  local versions_json

  requested="$1"

  if [ "$requested" = '.cvmrc' ] || [ -z "$requested" ]; then
    requested="$(cvm_read_rc)" || requested='latest'
  fi

  if [ "$requested" = 'default' ]; then
    requested="$(cvm_alias_target default)" || return 1
  fi

  resolved="$(cvm_alias_target "$requested" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    requested="$resolved"
  fi

  versions_json="$(cvm_remote_versions)" || return 1
  [ -n "$versions_json" ] || return 1

  if [ "$requested" = 'latest' ]; then
    printf '%s\n' "$versions_json" | cvm_node_json_filter 'latest' | tail -n 1
    return $?
  fi

  printf '%s\n' "$versions_json" | cvm_node_json_filter "$requested" | tail -n 1
}

cvm_install() {
  local requested
  local resolved
  local version_dir

  requested="${1-.cvmrc}"
  resolved="$(cvm_pick_remote_version "$requested")"

  if [ -z "$resolved" ]; then
    cvm_err "Unable to resolve a remote Claude Code version for: $requested"
    return 1
  fi

  version_dir="$(cvm_versions_dir)/$resolved"
  if [ -x "$version_dir/bin/claude" ]; then
    printf '%s\n' "cvm: version $resolved is already installed."
    return 0
  fi

  if ! cvm_has npm; then
    cvm_err 'npm is required to install Claude Code versions.'
    return 1
  fi

  cvm_ensure_dirs
  mkdir -p "$version_dir"

  printf '%s\n' "Installing Claude Code $resolved ..."
  if ! npm install -g --prefix "$version_dir" "$CVM_PACKAGE_NAME@$resolved"; then
    rm -rf "$version_dir"
    cvm_err "Installation failed for Claude Code $resolved"
    return 1
  fi

  printf '%s\n' "Installed Claude Code $resolved to $version_dir"
}

cvm_activate_version() {
  local version
  local version_dir
  local stripped

  version="$1"
  version_dir="$(cvm_versions_dir)/$version"

  if [ ! -x "$version_dir/bin/claude" ]; then
    cvm_err "Claude Code $version is not installed."
    return 1
  fi

  stripped="$(cvm_strip_path)"
  export PATH="$version_dir/bin${stripped:+:$stripped}"
  export CVM_BIN="$version_dir/bin"
  export CVM_CURRENT_VERSION="$version"

  mkdir -p "$CVM_DIR"
  rm -f "$CVM_DIR/current"
  ln -s "$version_dir" "$CVM_DIR/current" 2>/dev/null || true

  printf '%s\n' "Now using Claude Code $version"
}

cvm_use() {
  local requested
  local resolved

  requested="${1-.cvmrc}"
  resolved="$(cvm_pick_local_version "$requested")"

  if [ -z "$resolved" ]; then
    cvm_err "Claude Code version not installed: $requested"
    return 1
  fi

  if [ "$resolved" = 'system' ]; then
    cvm_deactivate
    return 0
  fi

  cvm_activate_version "$resolved"
}

cvm_deactivate() {
  local stripped

  stripped="$(cvm_strip_path)"
  export PATH="$stripped"
  unset CVM_BIN
  unset CVM_CURRENT_VERSION

  rm -f "$CVM_DIR/current" 2>/dev/null || true
  printf '%s\n' 'cvm: deactivated.'
}

cvm_unload() {
  unset -f cvm
  unset -f cvm_help
  unset -f cvm_err
  unset -f cvm_has
  unset -f cvm_ensure_dirs
  unset -f cvm_versions_dir
  unset -f cvm_alias_dir
  unset -f cvm_cache_dir
  unset -f cvm_strip_path
  unset -f cvm_find_rc_file
  unset -f cvm_read_rc
  unset -f cvm_alias_path
  unset -f cvm_alias_target
  unset -f cvm_is_exact_version
  unset -f cvm_node_json_filter
  unset -f cvm_local_versions
  unset -f cvm_remote_versions
  unset -f cvm_pick_local_version
  unset -f cvm_pick_remote_version
  unset -f cvm_install
  unset -f cvm_activate_version
  unset -f cvm_use
  unset -f cvm_deactivate
  unset -f cvm_unload
  unset -f cvm_current
  unset -f cvm_ls
  unset -f cvm_ls_remote
  unset -f cvm_version
  unset -f cvm_version_remote
  unset -f cvm_which
  unset -f cvm_run
  unset -f cvm_exec
  unset -f cvm_alias
  unset -f cvm_unalias
  unset -f cvm_cache
}

cvm_current() {
  if [ -n "${CVM_CURRENT_VERSION-}" ]; then
    printf '%s\n' "$CVM_CURRENT_VERSION"
  else
    printf '%s\n' 'system'
  fi
}

cvm_ls() {
  local current
  local default_alias
  local version

  current="$(cvm_current)"
  default_alias="$(cvm_alias_target default 2>/dev/null || true)"

  if [ -n "$default_alias" ]; then
    printf '%s\n' "default -> $default_alias"
  fi

  if [ "$current" = 'system' ]; then
    printf '%s\n' '-> system'
  else
    printf '%s\n' '   system'
  fi

  cvm_local_versions | while IFS= read -r version; do
    [ -n "$version" ] || continue
    if [ "$version" = "$current" ]; then
      printf '%s\n' "-> $version"
    else
      printf '%s\n' "   $version"
    fi
  done
}

cvm_ls_remote() {
  local filter

  filter="${1-latest}"
  cvm_remote_versions | cvm_node_json_filter "$filter"
}

cvm_version() {
  local resolved

  resolved="$(cvm_pick_local_version "${1-.cvmrc}")" || true
  if [ -n "$resolved" ]; then
    printf '%s\n' "$resolved"
  else
    printf '%s\n' 'N/A'
    return 3
  fi
}

cvm_version_remote() {
  local resolved

  resolved="$(cvm_pick_remote_version "${1-latest}")" || true
  if [ -n "$resolved" ]; then
    printf '%s\n' "$resolved"
  else
    printf '%s\n' 'N/A'
    return 3
  fi
}

cvm_which() {
  local resolved
  local path

  resolved="$(cvm_pick_local_version "${1-.cvmrc}")" || true
  if [ -z "$resolved" ]; then
    cvm_err 'Version not installed.'
    return 1
  fi

  if [ "$resolved" = 'system' ]; then
    command -v claude
    return $?
  fi

  path="$(cvm_versions_dir)/$resolved/bin/claude"
  if [ -x "$path" ]; then
    printf '%s\n' "$path"
    return 0
  fi

  cvm_err "Executable not found for $resolved"
  return 1
}

cvm_exec() {
  local requested
  local resolved
  local version_dir
  local stripped

  requested="${1-}"
  if [ -z "$requested" ]; then
    cvm_err 'Usage: cvm exec <version> <command> [args...]'
    return 1
  fi

  shift
  if [ $# -eq 0 ]; then
    cvm_err 'Usage: cvm exec <version> <command> [args...]'
    return 1
  fi

  resolved="$(cvm_pick_local_version "$requested")" || true
  if [ -z "$resolved" ] || [ "$resolved" = 'system' ]; then
    cvm_err "Version not installed: $requested"
    return 1
  fi

  version_dir="$(cvm_versions_dir)/$resolved"
  stripped="$(cvm_strip_path)"
  PATH="$version_dir/bin${stripped:+:$stripped}" \
  CVM_BIN="$version_dir/bin" \
  CVM_CURRENT_VERSION="$resolved" \
  "$@"
}

cvm_run() {
  local requested

  requested="${1-}"
  if [ -z "$requested" ]; then
    cvm_err 'Usage: cvm run <version> [claude args...]'
    return 1
  fi

  shift
  cvm_exec "$requested" claude "$@"
}

cvm_alias() {
  local name
  local target
  local resolved

  cvm_ensure_dirs

  if [ $# -eq 0 ]; then
    find "$(cvm_alias_dir)" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | sort | while IFS= read -r name; do
      target="$(cvm_alias_target "$name")"
      printf '%s\n' "$name -> $target"
    done
    return 0
  fi

  name="$1"
  if [ $# -eq 1 ]; then
    cvm_alias_target "$name"
    return $?
  fi

  target="$2"
  resolved="$(cvm_pick_remote_version "$target" 2>/dev/null || true)"
  if [ -z "$resolved" ]; then
    resolved="$target"
  fi
  printf '%s\n' "$resolved" >"$(cvm_alias_path "$name")"
  printf '%s\n' "$name -> $resolved"
}

cvm_unalias() {
  local path

  if [ $# -eq 0 ]; then
    cvm_err 'Usage: cvm unalias <name>'
    return 1
  fi

  path="$(cvm_alias_path "$1")"
  if [ -f "$path" ]; then
    rm -f "$path"
    printf '%s\n' "Deleted alias $1"
    return 0
  fi

  cvm_err "Alias not found: $1"
  return 1
}

cvm_uninstall() {
  local requested
  local resolved
  local version_dir

  requested="${1-}"
  if [ -z "$requested" ]; then
    cvm_err 'Usage: cvm uninstall <version>'
    return 1
  fi

  resolved="$(cvm_pick_local_version "$requested")" || true
  if [ -z "$resolved" ] || [ "$resolved" = 'system' ]; then
    cvm_err "Version not installed: $requested"
    return 1
  fi

  if [ "${CVM_CURRENT_VERSION-}" = "$resolved" ]; then
    cvm_deactivate >/dev/null
  fi

  version_dir="$(cvm_versions_dir)/$resolved"
  rm -rf "$version_dir"
  printf '%s\n' "Uninstalled Claude Code $resolved"
}

cvm_cache() {
  case "${1-}" in
    dir)
      cvm_cache_dir
      ;;
    clear)
      rm -rf "$(cvm_cache_dir)"
      mkdir -p "$(cvm_cache_dir)"
      printf '%s\n' 'cvm cache cleared.'
      ;;
    *)
      cvm_err 'Usage: cvm cache dir|clear'
      return 1
      ;;
  esac
}
