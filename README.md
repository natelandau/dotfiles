# Dotfiles

My personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/). One source of truth configures shells, CLI tools, packages, secrets, SSH, and macOS defaults across my Macs and Linux servers.

- Support for macOS and Linux
- ZSH and Bash configs, aliases, and functions sharing a numbered load order
- Package management across [Homebrew](https://brew.sh/), APT, [mise](https://mise.jdx.dev/), and [uv](https://docs.astral.sh/uv/)
- Secrets, SSH config, and SSH keys pulled from the [1Password CLI](https://developer.1password.com/docs/cli/) at apply time
- macOS defaults applied by script, plus app configs and a custom VS Code theme
- Per-machine roles (personal, dev, homelab) that decide what gets installed
- Configuration for my own CLI tools, including [halp](https://github.com/natelandau/halp), [vid-cleaner](https://github.com/natelandau/vid-cleaner), and [neatfile](https://github.com/natelandau/neatfile)

> **Note:** While many dotfile repositories are designed to be forked, mine are not. These are heavily customized for my personal use and likely contain many things you won't need or want to use. I'm posting it publicly so you can see how I manage my dotfiles and maybe get some ideas for how to manage your own.

## Before you start

You don't clone this repo by hand. `chezmoi init` clones it into chezmoi's source directory and takes over from there. Two things are worth knowing up front:

- The source files live in the `dotfiles/` subdirectory, not the repo root. A `.chezmoiroot` file points chezmoi there, so `chezmoi cd` lands in `dotfiles/`. Every path in this guide is relative to it.
- If you enable secrets, you must be signed in to the [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) before you apply. Templates read live values from 1Password at apply time, and apply fails if `op` can't authenticate.

## Install on a new machine

Install chezmoi and apply in one command. On a fresh machine, chezmoi installs itself, clones the repo, asks a few questions, then runs the bootstrap.

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply natelandau
```

On first init, chezmoi prompts for five answers and remembers them in its own config at `~/.config/chezmoi/chezmoi.toml`:

| Prompt                           | Controls                                                            |
| -------------------------------- | ------------------------------------------------------------------- |
| Use secrets from 1Password?      | Whether SSH keys, the SSH config, and secret-backed files get built |
| Is this a personal computer?     | Personal apps and the `090-personal` shell config                   |
| Is this computer in the homelab? | Server and media tooling                                            |
| Do you do development here?      | Developer tooling (gh, shellcheck, ansible, and similar)            |
| Email address                    | Git and contact email                                               |

What the bootstrap does next, in order:

1. Installs prerequisites: Homebrew on macOS, or `curl`, `unzip`, and `wget` on Linux.
2. Installs [uv](https://docs.astral.sh/uv/) for Python tools and [mise](https://mise.jdx.dev/) for cross-platform CLI tools.
3. Installs packages from the data files (Homebrew, APT, Mac App Store).
4. Writes all the config files and symlinks.
5. Runs the post-apply scripts: SSH keys, git credential manager, mise tools, and the nano config.
6. On macOS, applies system defaults.

Expect to run apply more than once on a brand-new machine. Some scripts install a tool that later scripts depend on, so the first pass installs mise, for example, and a later pass picks up the config and tools that need it. Two or three passes to a clean result is normal.

```bash
chezmoi apply
```

## Daily usage

Once installed, you edit the source files and let chezmoi push changes into place. The source directory is a git repo, so changes also need committing and pushing when you want them on your other machines.

| Command                     | What it does                                          |
| --------------------------- | ----------------------------------------------------- |
| `chezmoi edit ~/.zshrc`     | Edit the source version of a file in your editor      |
| `chezmoi cd`                | Drop into the source directory (lands in `dotfiles/`) |
| `chezmoi diff`              | Preview what apply would change                       |
| `chezmoi apply`             | Write pending changes to your home directory          |
| `chezmoi doctor`            | Check for common problems                             |
| `chezmoi status`            | Show which managed files differ                       |
| `chezmoi add ~/.config/foo` | Start managing a new file                             |
| `chezmoi update`            | Pull the latest from git, then apply                  |

To pull changes you made elsewhere onto the current machine, `chezmoi update` does the git pull and the apply together.

> **Warning:** If chezmoi hangs waiting for input, kill it with `killall chezmoi` and run `chezmoi apply` manually. Chezmoi locks its database while running, so a stuck process blocks the next command.

## How it's organized

Everything chezmoi manages lives under `dotfiles/`. Chezmoi's naming conventions encode the target file and how to process it.

| Prefix or suffix             | Meaning                                | Example                                            |
| ---------------------------- | -------------------------------------- | -------------------------------------------------- |
| `dot_`                       | Becomes a `.` in the target            | `dot_zshrc.tmpl` to `~/.zshrc`                     |
| `.tmpl`                      | Rendered as a Go template              | `config.tmpl`                                      |
| `symlink_`                   | Materialized as a symlink              | `symlink_settings.json.tmpl`                       |
| `executable_`                | Gets the executable bit                | `executable_osx-defaults.py`                       |
| `run_before_` / `run_after_` | Script run around each apply           | `run_after_30-mise-tools.sh.tmpl`                  |
| `run_onchange_`              | Script run only when its inputs change | `run_onchange_before_10-homebrew-packages.sh.tmpl` |

Shell config lives in `dotfiles/dot_config/dotfile_source/`. Both `.zshrc` and `.bashrc` source those files in numeric order, so paths and exports (low numbers) load before the aliases and functions that depend on them. Files ending in `.sh` load in both shells; `.bash` and `.zsh` files load only in their shell. Tool integrations live in the `third-party/` subdirectory.

## The parts that aren't obvious

Most of the repo is plain config files. A handful of areas are data-driven, and you edit data instead of editing the thing directly. These are the ones to know.

### Packages live in data, not in scripts

You never edit an install script to add a package. Package lists live in `.chezmoidata/packages.toml`, grouped first by manager and then by machine role:

```toml
[packages.homebrew.common]
    formulae = ["git", "jq", "ripgrep"]
[packages.homebrew.dev_computer]
    formulae = ["gh", "shellcheck"]
```

The four roles are `common`, `personal_computer`, `dev_computer`, and `homelab_member`. The `common` set installs everywhere; the others install only when that role is enabled. Each manager also has a `to_remove` list for tools you've dropped or moved between managers.

The install scripts are `run_onchange_` scripts keyed to the hash of `packages.toml`. Edit the file, and the matching installer re-runs on the next apply. Leave it alone, and the installer is skipped. The managers split responsibilities: Homebrew and APT for system packages, mise for cross-platform CLI tools so versions stay consistent, uv for Python tools, and `mas` for Mac App Store apps.

### Secrets come from 1Password by reference

No secret values live in this repo. The `.chezmoidata/onepassword.toml` file holds `op://` references, which name a vault, an item, and a field. Chezmoi resolves them at apply time through the `op` CLI:

```toml
[secrets]
    github_personal_access_token = "op://vault-id/item-id/personal_access_token"
```

To add a secret, add a reference here and read it in a template with the `onepassword` function. Nothing sensitive is ever written to the repo, only the pointer to where it lives. All of this is gated behind `use_secrets`, so machines with that turned off skip it cleanly. You can flip it any time in `~/.config/chezmoi/chezmoi.toml`.

### SSH keys and the SSH config are generated per server

This is the most template-heavy area, driven by `.chezmoidata/remote_servers.toml`. Each server entry carries a 1Password item ID and a couple of flags:

```toml
[remote_servers.macmini]
    add_to_ssh_config = true
    name              = "mini"
    op_id             = "ptff236gzxt5w4zsenpxjfrv3i"
    tailscale_ip      = true
```

Two things read this list:

- **SSH keys.** A post-apply script pulls each server's private and public key out of its 1Password item and writes them to `~/.ssh_keys/<name>` with the right permissions.
- **The SSH config.** `dot_ssh/config.tmpl` generates a `Host` block per server, filling in user, hostname, and port from live 1Password fields. When `tailscale_ip` is true, it adds a second host prefixed with `t` (so `mini` gets a `tmini`) pointed at the Tailscale address. The `add_to_ssh_config` flag controls whether a server appears in the config at all.

To add a server:

1. Create a 1Password item with these fields: `user`, `hostname`, `port`, a private key field labeled `privkey` (or `private key`), a public key field labeled `pubkey` (or `public key`), and `tailscale_ip` if you want a Tailscale host.
2. Copy the item's UUID.
3. Add an entry to `remote_servers.toml` with that `op_id` and the flags you want.

Apply, and both the key files and the SSH host blocks appear. To remove a server, delete its entry from `remote_servers.toml` and delete the 1Password item. Everything here depends on `use_secrets`.

### Configs only install when their tool exists

You don't get a Cursor config on a machine without Cursor. The `.chezmoidata/tool_configs.toml` file maps a binary name to the config paths that depend on it:

```toml
[tool_configs]
cursor = [".cursor", "Library/Application Support/Cursor"]
ghostty = [".config/ghostty"]
```

If the binary isn't on `PATH`, `.chezmoiignore` skips those paths. This keeps homelab boxes from getting GUI app configs they'd never use. To gate a new tool's config the same way, add a line here. More complex conditions (role flags, OS checks) stay written out explicitly in `.chezmoiignore`.

### macOS system defaults

System defaults live in a Python script at `bin/executable_osx-defaults.py`, covering Finder, the Dock, the trackpad, the keyboard, and more. A `run_onchange_` script re-runs it whenever the script changes. Edit the settings, apply, and the new defaults take effect. This step is skipped on Linux and in CI.

Some macOS apps still need a manual step. Terminal profiles live in `~/.config/applications/terminal`; import them with **Terminal > Settings > Profiles > Import**.

### Machine-local overrides

For settings that belong to one machine and shouldn't be tracked, the shells source `~/.dotfiles.local` last if it exists. Put one-off exports or aliases there and they stay off git.

## Working on the repo

The repo uses [uv](https://docs.astral.sh/uv/) for Python tooling, [duty](https://pawamoy.github.io/duty/) as the task runner, and [prek](https://github.com/j178/prek) for pre-commit hooks.

```bash
uv sync                            # install Python dependencies
uv run prek install --install-hooks # install the git hooks
uv run duty lint                   # run typos check and pre-commit hooks
```

Commit with [commitizen](https://commitizen-tools.github.io/commitizen/) to keep messages in the conventional-commit format the hooks enforce:

```bash
git add .
uv run cz c
git push
```

## Quick reference

| I want to...                  | Do this                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| Add or remove a package       | Edit `.chezmoidata/packages.toml`, then `chezmoi apply`        |
| Add a server and its keys     | Add an entry to `.chezmoidata/remote_servers.toml`, then apply |
| Add a secret                  | Add an `op://` reference to `.chezmoidata/onepassword.toml`    |
| Gate a config on a tool       | Add a line to `.chezmoidata/tool_configs.toml`                 |
| Change macOS defaults         | Edit `bin/executable_osx-defaults.py`, then apply              |
| Change a machine's role       | Edit `~/.config/chezmoi/chezmoi.toml`, then apply              |
| Set a machine-only override   | Add it to `~/.dotfiles.local`                                  |
| Sync changes between machines | `chezmoi cd` and push, then `chezmoi update` on the others     |

## License

This repository is licensed under the terms in [LICENSE](LICENSE).
