# shellcheck disable=SC1090

if [ -e "/Applications/iTerm.app" ]; then
    if [[ -n ${BASH} ]]; then
        if [[ -f ~/.iterm2_shell_integration.bash ]]; then
            source ~/.iterm2_shell_integration.bash
        else
            curl -L https://iterm2.com/shell_integration/bash \
                -o ~/.iterm2_shell_integration.bash &>/dev/null
        fi
    elif [[ -n ${ZSH_NAME} ]]; then
        if [[ -f ~/.iterm2_shell_integration.zsh ]]; then
            # export ITERM2_SQUELCH_MARK=1
            source ~/.iterm2_shell_integration.zsh
        else
            curl -L https://iterm2.com/shell_integration/zsh \
                -o ~/.iterm2_shell_integration.zsh &>/dev/null
        fi
    fi
fi
