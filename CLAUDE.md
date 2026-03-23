# CLAUDE.md

## Project Overview

Personal dotfiles managed with [Chezmoi](https://www.chezmoi.io/). Supports macOS, Debian, and Ubuntu. Includes shell configs (ZSH/Bash), CLI tool configurations, package management (Homebrew, APT, uv), secrets management via 1Password CLI, SSH config, macOS defaults, and custom app configs.

## Repository Structure

- `dotfiles/` - Chezmoi-managed dotfiles (uses chezmoi naming conventions like `dot_`, `.tmpl`, `symlink_`)
- `dotfiles/.chezmoidata/` - Data files for chezmoi templates (packages, constants, servers, etc.)
- `dotfiles/.chezmoitemplates/` - Reusable chezmoi templates
- `dotfiles/.assets/` - Static assets (claude config, iTerm2 themes, Terminal themes)
- `dotfiles/dot_config/dotfile_source/` - Shell source files loaded by `.bashrc`/`.zshrc`
- `dotfiles/dot_config/dotfile_source/third-party/` - Shell integrations for third-party tools
- `duties.py` - Project task runner (using `duty` library)

## Commands

```bash
# Lint
uv run duty lint              # Run all linting (typos + pre-commit hooks)
uv run duty typos             # Check for typos
uv run duty clean             # Remove .DS_Store files

# Dependencies
uv sync                       # Install/sync Python dependencies
uv run duty update            # Update uv lock, sync, and pre-commit hooks

# Chezmoi
chezmoi apply                 # Apply dotfiles to the system
chezmoi diff                  # Preview changes before applying
```

## Conventions

### Chezmoi file naming

Files in `dotfiles/` use chezmoi naming conventions:
- `dot_` prefix = `.` in target (e.g., `dot_zshrc` -> `.zshrc`)
- `.tmpl` suffix = Go template file processed by chezmoi
- `symlink_` prefix = symlink in target
- `executable_` prefix = file gets executable permission

### Shell source files

Files in `dotfiles/dot_config/dotfile_source/` follow a numbered naming convention for load order:
- `000-` through `090-` for core shell config
- `third-party/` subdirectory for tool-specific integrations
- `.sh` files are sourced by both bash and zsh
- `.bash` / `.zsh` files are shell-specific

### Pre-commit hooks

Pre-commit is configured with `prek` (a pre-commit alternative). Hooks include:
- commitizen (commit message format)
- standard pre-commit checks (large files, merge conflicts, trailing whitespace, etc.)
- gitleaks (secret detection)
- committed (commit message linting)
- typos (spell checking)
- shellcheck (shell script linting, excludes zsh files)

### Commit messages

Use angular-style conventional commits: `<type>(<scope>): <subject>`.

### Data files

Package lists, server configs, and other data live in `dotfiles/.chezmoidata/*.toml`. Edit these files to add/remove packages or server configurations.
