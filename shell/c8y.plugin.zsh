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

            # homebrew only: Add completions folder to the fpath so zsh can find it
            if command -v brew &>/dev/null; then
                FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
                chmod -R go-w "$(brew --prefix)/share"
            fi

            # init completions
            autoload -U compinit; compinit

            if [[ -n "$ZSH_CUSTOM" ]]; then
                mkdir -p "$ZSH_CUSTOM/plugins/c8y"

                if [ ! -f "$ZSH_CUSTOM/plugins/c8y/_c8y" ]; then
                    c8y completion zsh > "$ZSH_CUSTOM/plugins/c8y/_c8y"
                    echo -e "${green}Updated c8y completions${normal}"
                    source "$HOME/.zshrc"
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
# -------------
# session
# -------------
# Description: Get the current cumulocity session
# Usage:
#   session
#
session() {
    c8y sessions get "$@"
}

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
