# cvm

`cvm` is a version manager for Claude Code, intentionally modeled after `nvm`.

[MIT licensed](./LICENSE) and designed to live comfortably in a public GitHub repository.

It follows the same core philosophy:

- user-local installation
- shell function entrypoint
- per-version directories under a home-managed root
- `PATH` switching via `use`
- aliases like `default`
- project pinning via `.cvmrc`

## Runtime requirements

`cvm` stays shell-first like `nvm`, but its version parsing is implemented with Node.js rather than Python.

- required: `bash` or `zsh`
- required: `node`
- required: `npm`
- not required: `python`

This keeps the dependency model closer to how Claude Code users already work, and avoids assuming Python exists on Windows by default.

## Why

Claude Code moves quickly, and teams may want to:

- pin a project to a known-good Claude Code version
- compare behaviors between versions
- roll back quickly after a regression
- avoid a single mutable global install

## Command surface

The command names mirror `nvm` wherever they make sense for Claude Code:

```sh
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
```

## Layout

This repository is intentionally close to the `nvm` shape:

- `cvm.sh`: main shell implementation
- `cvm-exec`: helper executable for subprocess execution
- `install.sh`: profile bootstrapper
- `bash_completion`: shell completion
- `lib/version-filter.js`: Node-based version sorting/filtering helper
- `package.json`: repository metadata for npm/GitHub ecosystems

Runtime data lives under `~/.cvm` by default:

```text
~/.cvm/
  alias/
    default
  current -> versions/1.0.117
  versions/
    1.0.117/
      bin/claude
      lib/node_modules/@anthropic-ai/claude-code
```

## Installation

Clone the repository and run:

```sh
./install.sh
source ~/.zshrc
```

If your shell profile is not `~/.zshrc`, source the file printed by the installer.

## GitHub

GitHub organization target: [cvm-sh/cvm](https://github.com/cvm-sh/cvm)

## Usage

Install the latest Claude Code:

```sh
cvm install latest
```

Install a specific version:

```sh
cvm install 1.0.117
```

Switch versions in the current shell:

```sh
cvm use 1.0.117
claude --version
```

Set a default:

```sh
cvm alias default 1.0.117
```

Pin a project with `.cvmrc`:

```sh
echo "1.0.117" > .cvmrc
cvm install
cvm use
```

Run one command on another version without switching your shell:

```sh
cvm run 1.0.117 --version
cvm exec 1.0.117 claude doctor
```

## Installation model

Each Claude Code version is installed with npm into an isolated prefix:

```sh
npm install -g --prefix "$HOME/.cvm/versions/<version>" "@anthropic-ai/claude-code@<version>"
```

Then `cvm use` prepends that version's `bin` directory to `PATH`.

## Notes

- `cvm` currently assumes npm-based Claude Code installation.
- `system` means "use whatever `claude` is already on your PATH".
- `use`, like `nvm use`, only affects the current shell session.
- `cvm` intentionally starts as a shell-first tool, not a compiled binary.
- the repository is MIT licensed via [LICENSE](/Users/gaoyaxing/work/futures/AI/projects/cvm/LICENSE:1)
