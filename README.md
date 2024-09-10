Dotfiles, managed with [Chezmoi](https://www.chezmoi.io/).

-   Support for MacOS, Debian, and Ubuntu
-   ZSH and BASH configurations, aliases, and functions
-   Configurations for common command-line tools
-   Integrations for Python tooling from [uv](https://docs.astral.sh/uv/)
-   Package management with [Homebrew](https://brew.sh/), APT, and [uv](https://docs.astral.sh/uv/)
-   Configurations and integrations for MacOS applications
-   Secrets management with [1Password CLI](https://developer.1password.com/docs/cli/)
-   SSH configuration and key management with 1Password
-   OSX defaults management
-   Custom [vscode](https://code.visualstudio.com/) theme
-   Configuration for CLI scripts and packages including [halp](https://github.com/natelandau/halp), [vid-cleaner](https://github.com/natelandau/vid-cleaner), [jdfile](https://github.com/natelandau/jdfile), and others.
-   and more...

**IMPORTANT:** While many dotfile repositories are designed to be forked, mine are not. These are heavily customized for my personal use and likely contain many things you won't need or want to use. Posting publicly so you can see how I manage my dotfiles and maybe get some ideas for how to manage your own.

## Install

-   [Chezmoi](https://www.chezmoi.io/)
-   [1Password CLI](https://developer.1password.com/docs/cli/) (Optional, for secrets management)

**Ensure required software is installed before proceeding.** There are many ways to install Chezmoi. Check the [official documentation](https://www.chezmoi.io/install/) for the most up-to-date instructions. To install chezmoi and these dotfiles in a single command run the following:

## First Run

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply natelandau
```

Depending on the options selected during the installation, you may encounter errors on the first run. If you encounter an error, run `chezmoi apply`.

## Daily Usage

After Chezmoi is installed, use the following commands.

```bash
# Initialize chezmoi configuration and apply the dotfiles (first run)
chezmoi init natelandau

# Check for common problems.
chezmoi doctor

# Update dotfiles from the source directory.
chezmoi apply

# Pull the latest changes from your remote repo and runs chezmoi apply.
chezmoi update
```

Note that if chezmoi hangs waiting for user input, you will need to kill the process (`killall chezmoi`) and run `apply` manually, because chezmoi locks the database.

## Package management

Packages are managed with the appropriate tools:

-   [Homebrew](https://brew.sh/) for MacOS
-   APT for Debian-based systems
-   [uv](https://docs.astral.sh/uv/) for Python packages

To configure the packages to be installed or removed on a system, edit the `dotfiles/.chezmoidata/packages.toml` file.

## Managing Secrets

Secrets are managed in [1Password](https://developer.1password.com/docs/cli/). 1Password is not needed if Chezmoi is set to `use_secrets = false` in the `~/.config/chezmoi/chezmoi.toml` file.

**IMPORTANT:** The 1Password CLI must be installed and configured before using chezmoi secrets. Follow the [official documentation](https://developer.1password.com/docs/cli/) to install and configure the 1Password CLI.

### SSH Configuration

Adding and removing ssh configurations can be managed with 1Password. To add a new ssh configuration, follow these steps:

1. Add an SSH Key to 1Password and add the following fields:
    - `ssh_key`: The private key
    - `ssh_key.pub`: The public key
    - `user`: The username for the ssh connection
    - `hostname`: The hostname for the ssh connection
    - `port`: The port for the ssh connection (optional)
2. Copy the UUID of the new 1Password item.
3. Add the server's configuration to `.../dotfiles/.chezmoidata/remote_servers.toml`

To remove an ssh configuration, delete the server's configuration from `.../dotfiles/.chezmoidata/remote_servers.toml` and delete the 1Password item.

## MacOS Application Preferences

Certain MacOS applications need manual configuration.

#### iTerm2

iTerm2 Configurations and profiles are synced to `~/.config/applications/iterm2`.

The configuration file should be synced automatically. If it is not, `Preferences > General > Preferences` and select the `Load preferences from a custom folder or URL` option. Then select the `~/.config/applications/iterm2` directory.

Profiles are not synced automatically. Import the profiles by going to `Profiles > Other Actions > Import JSON Profiles` and import them from `~/.config/applications/iterm2/`.

### Terminal

Custom terminal configurations are stored in `~/.config/applications/terminal`. Import them with `Terminal > Preferences > Profiles > Import`.

## Editing Dotfiles

## Setup

1. Install [uv](https://docs.astral.sh/uv/) to enable integration with Python tooling.
2. Install the virtual environment with `uv sync`
3. Activate the virtual environment with `source .venv/bin/activate`
4. Install the pre-commit hooks with `pre-commit install --install-hooks`

## Committing changes

1. Activate the virtual environment with `source .venv/bin/activate`
2. Add changed files to the staging area with `git add .`
3. Run `cz c` to commit changes
4. Push to remote repository
