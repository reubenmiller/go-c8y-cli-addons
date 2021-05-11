#!/bin/zsh

# Force encoding
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

C8Y_SHELL=bash
if [[ "$BASH_VERSION" != "" ]]; then
    C8Y_SHELL=bash
elif [[ "$ZSH_VERSION" != "" ]]; then
    C8Y_SHELL=zsh
fi

install_bash_dependencies () {
    if [[ ! -d "$HOME/.bash_completion.d" ]]; then
        mkdir -p "$HOME/.bash_completion.d"
    fi

    if [ ! -f "$HOME/.bash_completion.d/complete_alias" ]; then
        echo "Installing bash completion for aliases"
        curl -sfL https://raw.githubusercontent.com/cykerway/complete-alias/master/complete_alias \
                > "$HOME/.bash_completion.d/complete_alias"
    fi

    # Enable completion for aliases
    [ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion
    [ -f "$HOME/.bash_completion.d/complete_alias" ] && source "$HOME/.bash_completion.d/complete_alias"
}

init-c8y () {
    if [[ $(command -v c8y) ]]; then
        if [ "$C8Y_SHELL" = "zsh" ]; then

            if [[ -n "$ZSH_CUSTOM" ]]; then
                mkdir -p "$ZSH_CUSTOM/plugins/c8y"

                if [ ! -f "$ZSH_CUSTOM/plugins/c8y/_c8y" ]; then
                    c8y completion zsh > "$ZSH_CUSTOM/plugins/c8y/_c8y"
                    echo -e "${green}Updated c8y completions. \n\n${bold}Please load your zsh profile again using 'source \$HOME/.zshrc'${normal}"
                fi
            fi
        fi

        if [ "$C8Y_SHELL" = "bash" ]; then
            install_bash_dependencies
            source <(c8y completion bash)
        fi
    fi
}

init-c8y

########################################################################
# c8y helpers
########################################################################
# -----------
# set-session
# -----------
# Description: Switch Cumulocity session interactively
# Usage:
#   set-session
#
set-session () {
    c8yenv=$( c8y sessions set --noColor=false $@ )
    code=$?
    if [ $code -ne 0 ]; then
        echo "Set session failed"
        (exit $code)
        return
    fi
    eval "$c8yenv"
}

# -----------
# clear-session
# -----------
# Description: Clear all cumulocity session variables
# Usage:
#   clear-session
#
clear-session () {
    source <(c8y sessions clear)
}

# -----------
# clear-c8ypassphrase
# -----------
# Description: Clear the encryption passphrase environment variables
# Usage:
#   clear-c8ypassphrase
#
clear-c8ypassphrase () {
    unset C8Y_PASSPHRASE
    unset C8Y_PASSPHRASE_TEXT
}

# -----------
# set-c8ymode-xxxx
# -----------
# Description: Set temporary mode by setting the environment variables
# Usage:
#   set-c8ymode-dev     (enable PUT, POST and DELETE)
#   set-c8ymode-qual    (enable PUT, POST)
#   set-c8ymode-prod    (disable PUT, POST and DELETE)
#
set-c8ymode () {
    source <(c8y settings update --shell auto mode $1);
    echo -e "\e[32mEnabled $1 mode (temporarily)\e[0m";
}
set-c8ymode-dev () { set-c8ymode dev; }
set-c8ymode-qual () { set-c8ymode qual; }
set-c8ymode-prod () { set-c8ymode prod; }

update-c8y () {
    git -C "$HOME/.go-c8y-cli" pull --ff-only > /dev/null
    "$HOME/.go-c8y-cli/install.sh"
}

########################################################################
# c8y aliases
########################################################################

set_c8y_alias () {
    if [ "$C8Y_SHELL" = "zsh" ]; then
        set_c8y_zsh_alias
    elif [ "$C8Y_SHELL" = "bash" ]; then
        set_c8y_bash_alias
    fi
}

set_c8y_bash_alias () {

    # alarms
    alias alarms=c8y\ alarms\ list
    complete -F _complete_alias alarms

    # apps
    alias apps=c8y\ applications\ list
    complete -F _complete_alias apps

    # devices
    alias devices=c8y\ devices\ list
    complete -F _complete_alias devices

    # events
    alias events=c8y\ events\ list
    complete -F _complete_alias events

    # fmo
    alias fmo=c8y\ inventory\ find\ --query
    complete -F _complete_alias fmo

    # measurements
    alias measurements=c8y\ measurements\ list
    complete -F _complete_alias measurements

    # operations
    alias ops=c8y\ operations\ list
    complete -F _complete_alias ops

    # series
    alias series=c8y\ measurements\ getSeries
    complete -F _complete_alias series

    #
    # Single item getters
    #
    # alarm
    alias alarm=c8y\ alarms\ get\ --id
    complete -F _complete_alias alarm

    # app
    alias app=c8y\ applications\ get\ --id
    complete -F _complete_alias app

    # event
    alias event=c8y\ events\ get\ --id
    complete -F _complete_alias event

    # m
    alias m=c8y\ measurements\ get\ --id
    complete -F _complete_alias m

    # mo
    alias mo=c8y\ inventory\ get\ --id
    complete -F _complete_alias mo

    # op
    alias op=c8y\ operations\ get\ --id
    complete -F _complete_alias op

    # session
    alias session=c8y\ sessions\ get
    complete -F _complete_alias session
}

set_c8y_zsh_alias () {
    # alarms
    alias alarms=c8y\ alarms\ list

    # apps
    alias apps=c8y\ applications\ list

    # devices
    alias devices=c8y\ devices\ list

    # events
    alias events=c8y\ events\ list

    # fmo
    alias fmo=c8y\ inventory\ find\ --query

    # measurements
    alias measurements=c8y\ measurements\ list

    # operations
    alias ops=c8y\ operations\ list

    # series
    alias series=c8y\ measurements\ getSeries

    #
    # Single item getters
    #
    # alarm
    alias alarm=c8y\ alarms\ get\ --id

    # app
    alias app=c8y\ applications\ get\ --id

    # event
    alias event=c8y\ events\ get\ --id

    # m
    alias m=c8y\ measurements\ get\ --id

    # mo
    alias mo=c8y\ inventory\ get\ --id

    # op
    alias op=c8y\ operations\ get\ --id

    # session
    alias session=c8y\ sessions\ get
}

set_c8y_alias
