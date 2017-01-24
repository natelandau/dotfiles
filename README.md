# dotfiles
This repo contains all my dotfiles, configuration files, ~/bin scripts, and a series of scripts to install everything where it needs to go.

# Cloning this repo to a new computer
The first step needed to use these dotfiles is to clone this repo into the $HOME directory.  To make this easy, I created [a gist](https://gist.github.com/natelandau/b6ec165862277f3a7a4beff76da53a9c) which can easily be run with the following command:

```
curl -SL https://gist.githubusercontent.com/natelandau/b3e1dfba7491137f0a0f5e25721fffc2/raw/d98763695a0ddef1de9db2383f43149005423f20/bootstrapNewMac | bash
```

This gist creates a script `~/bootstrap.sh` in your home directory which completes the following tasks

1. Creates a new public SSH key if needed
2. Copies your public key to your clipboard
3. Opens Github to allow you to add this public key to your 'known keys'
4. Clones this dotfiles repo to your home directory

See. Easy. Now you're ready to invoke `install.sh` and get your new computer working.

# How it works
There are three distinct areas of `install.sh` which are executed in order.  These are:

1. **Bootstrapping** - Installing base components such as Command Line Tools, Homebrew, Node, RVM, etc.
2. **Installation** - Symlinking dotfiles and installing executables such as NPM Packages, Homebrew Casks, etc.
3. **Configuration** - Configures installed packages and apps.

The files are organized into three subdirectories.

```
dotfiles
├── bin
├── config
│   ├── bash
│   └── shell
├── install.sh
└── lib
    ├── bootstrap
    ├── configure
    └── config-install.yaml
```

* **bin** - Symlinked to `~/bin` and is added to your $PATH.
* **config** - Contains the elements needed to configure your environment and specific apps.
* config/**bash** - Files in this directory are *sourced* by `.bash_profile`.
* config/**shell** - Files here are symlinked to your local environment. Ahem, dotfiles.
* **lib** - Contains the scripts and configuration for `install.sh`
* lib/**bootstrap** - Scripts here are executed by `install.sh` first.
* lib/**configure** - Scripts here are exectuted by `install.sh` after packages have been installed
* lib/**config-install.yaml** - This YAML file contains the list of symlinks to be created, as well as the packages to be installed.

# Private Files

Sometimes there are files which contain private information. These might be API keys, local directory structures, or anything else you want to keep hidden.

Private files are held in a separate git repo named private. This repository is added as a git-submodule and files within it are symlinked to `$HOME` or sourced to the Bash terminal.

The private repository works similar to the main one. 

It contains a symlink manifest named `private-install.yaml` to symlink dotfiles. Which, in turn, contains a list:

```
privateSymlinks:
  - ~/.somefile:           private/config/shell/somefile
  - ~/.someotherfile:      private/config/shell/someotherfile
```

In addition, this private repo contains `config/bash`. A directory which contains any private .bash files which will be sourced when you launch a terminal.
