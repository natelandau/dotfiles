# Use Antibody
# https://getantibody.github.io/

# Bundle Antibody
antibody bundle < ${HOME}/.zsh_plugins.txt > ${HOME}/.zsh_plugins.sh

# Use Antibody
if [ -f ${HOME}/.zsh_plugins.sh ]; then
  source ${HOME}/.zsh_plugins.sh
else
  echo "Could not find '${HOME}/.zsh_plugins.sh'. Aborting antibody load"
fi

# Configure plugins
# ----------------------

# https://github.com/zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'  # Use a lighter gray for the suggested text
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
