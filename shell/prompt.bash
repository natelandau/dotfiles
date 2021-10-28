# shellcheck disable=SC2034,SC2154
if [[ ${OSTYPE} =~ linux ]]; then

    _promptGit_() {
        local s=''
        local branchName=''

        # Check if the current directory is in a Git repository.
        if [ "$(
            git rev-parse --is-inside-work-tree &>/dev/null
            echo "${?}"
        )" == '0' ]; then
            # check if the current directory is in .git before running git checks

            if [ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" == 'false' ]; then

                # Ensure the index is up to date.
                git update-index --really-refresh -q &>/dev/null

                # Check for uncommitted changes in the index.
                if ! git diff --quiet --ignore-submodules --cached; then
                    s+='+'
                fi

                # Check for unstaged changes.
                if ! git diff-files --quiet --ignore-submodules --; then
                    s+='!'
                fi

                # Check for untracked files.
                if [ -n "$(git ls-files --others --exclude-standard)" ]; then
                    s+='?'
                fi

                # Check for stashed files.
                if git rev-parse --verify refs/stash &>/dev/null; then
                    s+='$'
                fi
            fi

            # Get the short symbolic ref.
            # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
            # Otherwise, just give up.
            branchName="$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
                || git rev-parse --short HEAD 2>/dev/null \
                || echo '(unknown)')"

            [ -n "${s}" ] && s=" [${s}]"

            echo -e "${1}${branchName}${s}"
        else
            return
        fi
    }

    export PS1="\[$WHITE\]________________________________________________________________________________\n| \
\[${bold}${purple}\]\u \[$white\]at \[$yellow\]\h \
\[$white\]in \[$green\]\w\[$white\]\$([[ -n \$(git branch 2> /dev/null) ]] && echo \" on \")\
\[$purple\]\$(_promptGit_ \"$purple\")\[$white\]\[$reset\] \
\n\[$white\]| =>\[$reset\] "
    export PS2="\[$white\]→ $reset"

else
    # ####################################################
    #
    # This bash script reads a series of plugins in to piece together
    # a prompt heavily based on Powerline.  Two folders of plugins
    # are used, a 'top' and a 'bottom'. Together they can create
    # a two line prompt
    #
    # The order of the plugins is alphabetical as they are
    # read from the directory.
    #
    # Each plugin must contain the following variables:
    #
    #   local fground               # The foreground text color
    #   local bground               # The background color
    #   local invertedBckgrnd       # Color to be used in the next plugin for the powerline fine
    #   local enabled=true          # If false, this segment will be ignored
    #   local seperator=""         # Optional, the seperator character between prompt elements
    #
    # ####################################################

    _setPrompt_() {
        local lastExit=$?
        local reset seperator oldBG ii iii
        divider=""
        topPluginLocation="${DOTFILES_LOCATION}/shell/prompt-plugins-bash/top"
        bottomPluginLocation="${DOTFILES_LOCATION}/shell/prompt-plugins-bash/bottom"
        PS1="" # Add a newline at the beginning of the prompt
        oldBG=""

        reset="\e[0m"
        bold="\e[1m"
        blink="\e[5m"
        underline="\e[4m"
        local fore_whi="\e[38;5;231m"
        local fore_blu="\e[38;5;27m"
        local fore_ora="\e[38;5;208m"
        local fore_red="\e[38;5;1m"
        local fore_grn="\e[38;5;10m"
        local fore_pur="\e[38;5;5m"
        local fore_yel="\e[38;5;3m"
        local fore_blck="\e[38;5;233m"
        local fore_mag="\e[38;5;9m"
        local fore_gry="\e[38;5;241m"
        local fore_blu2="\e[38;5;38m"
        local fore_gry2="\e[38;5;239m"
        local back_whi="\e[48;5;231m"
        local back_blu="\e[48;5;27m"
        local back_ora="\e[48;5;208m"
        local back_red="\e[48;5;1m"
        local back_grn="\e[48;5;10m"
        local back_pur="\e[48;5;5m"
        local back_yel="\e[48;5;3m"
        local back_blck="\e[48;5;233m"
        local back_mag="\e[48;5;9m"
        local back_gry="\e[48;5;241m"
        local back_blu2="\e[48;5;38m"
        local back_gry2="\e[48;5;239m"

        _parseSegments_() {
            # This function is called by the prompt plugins to create the prompt

            local segment="$1"
            local fg="$2"
            local bg="$3"
            local invertedBckgrnd="$4"
            local enabled="${5:-true}"
            local passedSeperator="$6"

            if ! ${enabled}; then return; fi

            if [ "$6" ]; then
                local sep="$6"
            else
                local sep="$divider"
            fi

            # if there was a previous segment, print the separator
            if [ "$ii" -gt 0 ]; then
                PS1+="${bg}${oldBG}${sep} ${reset}"
            fi

            # Build the prompt from the plugin
            PS1+="${bg}${fg}"
            PS1+=$" ${segment}"
            PS1+=" ${reset}"

            oldBG="${invertedBckgrnd}"
        }

        # ########
        # Parse the top line
        # ########

        local ii=0
        if [ -d "${topPluginLocation}" ]; then
            for plugin in "${topPluginLocation}"/*.bash; do
                # shellcheck disable=SC1090
                [ -f "${plugin}" ] && source "${plugin}"
                [ -f "${plugin}" ] && ((ii++))
            done
        fi

        # Add a seperator at the end of the line
        PS1+="${oldBG}${divider} ${reset}"

        # ########
        # Parse the bottom line
        # ########

        # Add a newline if any plugins were added to the top line
        [ "$ii" -gt 0 ] && PS1+="\n"

        local ii=0
        if [ -d "${bottomPluginLocation}" ]; then
            for plugin in "${bottomPluginLocation}"/*.bash; do
                # shellcheck disable=SC1090
                [ -f "${plugin}" ] && source "${plugin}"
                [ -f "${plugin}" ] && ((ii++))
            done
        fi

        # If we don't have any bottom plugins, add a simple prompt
        [ "$ii" -eq 0 ] && PS1+="${back_gry}${fore_whi}  ${reset}" && oldBG="${back_gry}"

        # Add a seperator at the end of the line
        PS1+="${oldBG}${divider} ${reset}"

        export PS2="${fore_whi}→ ${reset}"
    }
    PROMPT_COMMAND=_setPrompt_
fi
