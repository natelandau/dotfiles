Dotfiles, managed with [Chezmoi](https://www.chezmoi.io/).

-   zsh and bash configurations, aliases, and functions
-   Configuration for common command-line tools
-   Integrations for Python tooling such as [Pyenv](https://github.com/pyenv/pyenv), [Poetry](https://python-poetry.org/), and [Pipx](https://pipx.pypa.io/stable/)
-   Configurations and integrations for MacOS applications
-   Secrets management with [1Password CLI](https://developer.1password.com/docs/cli/)
-   ssh configuration and key management with 1Password
-   OSX defaults management
-   Custom [vscode](https://code.visualstudio.com/) theme
-   Configuration for my CLI scripts [halp](https://github.com/natelandau/halp),[vid-cleaner](https://github.com/natelandau/vid-cleaner), [jdfile](https://github.com/natelandau/jdfile), and [brewup](https://github.com/natelandau/brewup)
-   and more...

## Install

-   [Chezmoi](https://www.chezmoi.io/)
-   [1Password CLI](https://developer.1password.com/docs/cli/) (Optional, for secrets management)

**Ensure required software is installed before proceeding.** There are many ways to install Chezmoi. Check the [official documentation](https://www.chezmoi.io/install/) for the most up-to-date instructions. To install chezmoi and these dotfiles in a single command run the following:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply natelandau
```

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

1. Install Python and [Poetry](https://python-poetry.org)
2. cd into the dotfiles directory with `chezmoi cd`
3. Run `poetry install` to install the development dependencies
4. Activate the Poetry virtual environment with `poetry shell`.
5. Install the pre-commit hooks with `pre-commit install --install-hooks`.

## Committing changes

1. Activate your Poetry environment with `poetry shell`
2. Add changed files to the staging area with `git add .`
3. Run `cz c` to commit changes
4. Push to remote repository

## Updating dotfiles

Run `chezmoi update` to apply changes to the dotfiles on other machines.
