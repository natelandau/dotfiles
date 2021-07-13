This repository contains my dotfiles for BASH and ZSH.  They are opinionated and based on my own work flows. I highly recommend that you read through the files and customize them for your own purposes.

# Installation
In `.zshrc` and `.bash_profile` ensure the correct directory is used for the `DOTFILES_LOCATION` variable.

Symlink the dotfiles from this repository to your user directory. To avoid doing this manually file-by-file, run the `install.sh` script.

## Bash Scripting Templates
My bash scripting templates and utilities now have their own repo.  You can access them at [natelandau/bash-scripting-templates](https://github.com/natelandau/bash-scripting-templates)

## macOS specific tweaks
I customized [Jeff Geerling's macOS configuration script](https://github.com/geerlingguy/dotfiles/blob/master/.osx) to set my macOS defaults.  Run this script with sudo privs.
```bash
sudo ./osx.sh
```

## lessfilter.sh
In the `bin/` directory is a script to help colorize files using `less`.  To use this script, make sure that `shell/test.sh` points to the correct location for the file.

## A Note on Code Reuse
I compiled these scripting utilities over many years without ever having an intention to make them public.  As a novice programmer, I have Googled, GitHubbed, and StackExchanged a path to solve my own scripting needs. I often lift a function whole-cloth from a GitHub repo don't keep track of its original location. I have done my best within these files to recreate my footsteps and give credit to the original creators of the code when possible. I fear that I missed as many as I found. My goal in making this repository public is not to take credit for the code written by others. If you recognize something that I didn't credit, please let me know.

## License
MIT
