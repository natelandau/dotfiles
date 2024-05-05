
# Load Plugins
# https://github.com/mattmc3/zsh_unplugged - Build your own zsh plugin manager
#############################################
# clone your plugin, set up an init.zsh, source it, and add to your fpath
_pluginload_() {
    local giturl="$1"
    local plugin_name=${${1##*/}%.git}
    local plugindir="${ZPLUGINDIR:-$HOME/.zsh/plugins}/$plugin_name"

    # clone if the plugin isn't there already
    if [[ ! -d "${plugindir}" ]]; then
        command git clone --depth 1 --recursive --shallow-submodules "${giturl}" "${plugindir}"
        [[ $? -eq 0 ]] || { echo "plugin-load: git clone failed $1" && return 1; }
    fi

    # symlink an init.zsh if there isn't one so the plugin is easy to source
    if [[ ! -f $plugindir/init.zsh ]]; then
        local initfiles=(
          # look for specific files first
          $plugindir/$plugin_name.plugin.zsh(N)
          $plugindir/$plugin_name.zsh(N)
          $plugindir/$plugin_name(N)
          $plugindir/$plugin_name.zsh-theme(N)
          # then do more aggressive globbing
          $plugindir/*.plugin.zsh(N)
          $plugindir/*.zsh(N)
          $plugindir/*.zsh-theme(N)
          $plugindir/*.sh(N)
        )
        [[ ${#initfiles[@]} -gt 0 ]] || { >&2 echo "plugin-load: no plugin init file found" && return 1; }
        command ln -s ${initfiles[1]} $plugindir/init.zsh
    fi

    # source the plugin
    source $plugindir/init.zsh

    # modify fpath
    fpath+=$plugindir
    [[ -d $plugindir/functions ]] && fpath+=$plugindir/functions
}

# set where we should store Zsh plugins
ZPLUGINDIR=${HOME}/.zsh/plugins

# add your plugins to this list
plugins=(
    # core plugins
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-completions

    # # user plugins
    marlonrichert/zsh-hist              # Run hist -h for help
    reegnz/jq-zsh-plugin                # Write interactive jq queries (Requires jq and fzf)
    MichaelAquilina/zsh-you-should-use  # Recommends aliases when typed
    rupa/z                              # Tracks your most used directories, based on 'frequency'
    darvid/zsh-poetry                   # activates poetry venvs

    # Additional completions
    zpm-zsh/ssh

    # prompts
    # denysdovhan/spaceship-prompt
    romkatv/powerlevel10k

    # load these last
    # zsh-users/zsh-syntax-highlighting
    zdharma-continuum/fast-syntax-highlighting
    zsh-users/zsh-history-substring-search
)

# load your plugins (clone, source, and add to fpath)
for repo in ${plugins[@]}; do
  _pluginload_ https://github.com/${repo}.git
done
unset repo

# Update ZSH Plugins
function zshup () {
  local plugindir="${ZPLUGINDIR:-$HOME/.zsh/plugins}"
  for d in $plugindir/*/.git(/); do
    echo "Updating ${d:h:t}..."
    command git -C "${d:h}" pull --ff --recurse-submodules --depth 1 --rebase --autostash
  done
}

# CONFIGURE PLUGINS
#############################################
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242' # Use a lighter gray for the suggested text
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
FAST_HIGHLIGHT[use_brackets]=1


# History Search with alt+up/down arrows


# start typing + [Up-Arrow] - fuzzy find history forward
if [[ -n "$terminfo[kcuu1]" ]]; then
    bindkey "$terminfo[kcuu1]" history-substring-search-up
else
    bindkey '^[^[[A' history-substring-search-up
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ -n "$terminfo[kcud1]" ]]; then
    bindkey "$terminfo[kcud1]" history-substring-search-down
else
    bindkey '^[^[[B' history-substring-search-down
fi
