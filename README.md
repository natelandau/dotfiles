This repository contains my dotfiles for BASH and ZSH. They are opinionated and based on my own work flows. I highly recommend that you read through the files and customize them for your own purposes.

# Installation

In `.zshrc` and `.bash_profile` ensure the correct directory is used for the `DOTFILES_LOCATION` variable.

Symlink the dotfiles from this repository to your user directory. To avoid doing this manually file-by-file, run the `install.sh` script.

## Option per-computer overrides

Place any computer specific bash or zsh aliases, functions, or settings in `~/.dotfiles.local`. Anything within that file will be sourced into your environment.

## Shell Scripting Templates

My bash scripting templates and utilities now have their own repo. You can access them at [natelandau/shell-scripting-templates](https://github.com/natelandau/shell-scripting-templates)

## macOS specific tweaks

I customized [Jeff Geerling's macOS configuration script](https://github.com/geerlingguy/dotfiles/blob/master/.osx) to set my macOS defaults. Run this script with sudo privileges.

```bash
sudo ./osx.sh
```

## lessfilter.sh

In the `bin/` directory is a script to help colorize files using `less`. To use this script, make sure that `shell/text.sh` points to the correct location for the file.

## A Note on Code Reuse

I compiled these scripting utilities over many years without ever having an intention to make them public. As a novice programmer, I have Googled, GitHubbed, and StackExchanged a path to solve my own scripting needs. I often lift a function whole-cloth from a GitHub repo don't keep track of its original location. I have done my best within these files to recreate my footsteps and give credit to the original creators of the code when possible. I fear that I missed as many as I found. My goal in making this repository public is not to take credit for the code written by others. If you recognize something that I didn't credit, please let me know.

## Contributing

### Setup

1. Install Python 3.11 and [Poetry](https://python-poetry.org)
2. Clone this repository. `git clone https://github.com/natelandau/dotfiles.git`
3. Install the Poetry environment with `poetry install`.
4. Activate your Poetry environment with `poetry shell`.
5. Install the pre-commit hooks with `pre-commit install --install-hooks`.

### Developing

-   Activate your Poetry environment with `poetry shell`.
-   This project follows the [Conventional Commits](https://www.conventionalcommits.org/) standard to automate [Semantic Versioning](https://semver.org/) and [Keep A Changelog](https://keepachangelog.com/) with [Commitizen](https://github.com/commitizen-tools/commitizen).
    -   When you're ready to commit changes run `cz c`
-   Run `poe` from within the development environment to print a list of [Poe the Poet](https://github.com/nat-n/poethepoet) tasks available to run on this project. Common commands:
    -   `poe lint` runs all linters and tests
-   Run `poetry add {package}` from within the development environment to install a runtime dependency and add it to `pyproject.toml` and `poetry.lock`.
-   Run `poetry remove {package}` from within the development environment to uninstall a runtime dependency and remove it from `pyproject.toml` and `poetry.lock`.
-   Run `poetry update` from within the development environment to upgrade all dependencies to the latest versions allowed by `pyproject.toml`.

## License

MIT
