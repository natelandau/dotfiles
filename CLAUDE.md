# CLAUDE.md

Personal dotfiles managed with chezmoi for macOS, Debian, Ubuntu, and Synology DSM. Source root:
`dotfiles/` (set by `.chezmoiroot`).

## Repository Structure

- `dotfiles/.chezmoidata/` - Data files for chezmoi templates (packages, constants, tool configs,
  1Password references)
- `dotfiles/.chezmoitemplates/` - Reusable chezmoi templates
- `dotfiles/.chezmoiscripts/` - `run_before`/`run_after` install scripts, run in numeric order
- `dotfiles/.assets/` - Static assets (Claude config, Terminal themes)
- `dotfiles/dot_config/dotfile_source/` - Shell source files loaded by `.bashrc`/`.zshrc`
- `duties.py` - Project task runner (`duty`)
- `.github/workflows/automated_tests.yml` - CI: lint + `chezmoi apply` on Ubuntu and macOS, with
  shared steps in `.github/actions/`

## Commands

```bash
uv run duty lint      # typos + pre-commit hooks
uv sync               # install Python dependencies
uv run duty update    # upgrade uv lock, sync, and pre-commit hooks
chezmoi diff          # preview changes; run chezmoi apply only when the user asks
```

Running `chezmoi apply` 2-3 times is expected: early scripts install tools (mise, then
mise-managed binaries) that later configs need.

## Conventions

- Chezmoi attribute prefixes must follow chezmoi's documented order (`modify_private_`, not
  `private_modify_`).
- Shell source files: load order is the numeric prefix (`000-` to `090-`). `.sh` loads in bash and
  zsh; `.bash`/`.zsh` load in one shell. `third-party/` holds tool integrations.
- Pre-commit runs through `prek`. Hooks lint commit messages (commitizen, committed) and run
  shellcheck on everything except zsh files.
- Add or remove packages in `dotfiles/.chezmoidata/packages.toml`.

## Claude Code configuration

User-scoped Claude Code configuration (`~/.claude/`) is managed from this repo:

- `dotfiles/.assets/claude/` holds the real files. `dotfiles/dot_claude/` holds one
  `symlink_<name>.tmpl` per entry, which chezmoi turns into `~/.claude/<name>` ->
  `.assets/claude/<name>`.
- Edits under `.assets/claude/` take effect immediately; no apply needed.
- A new file or folder under `.assets/claude/` needs a matching `symlink_<name>.tmpl` in
  `dot_claude/`.
