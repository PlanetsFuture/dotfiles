# vars
DOTFILES=$HOME/.dotfiles
EMACSD=$HOME/danny-emacs

source ~/antigen.zsh

# Load the oh-my-zsb's library.
antigen use oh-my-zsh

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme sonicradish

# Autosuggestions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
# Tell Antigen that you're done.
antigen apply

[ -f "/Users/dannyramirez/.ghcup/env" ] && source "/Users/dannyramirez/.ghcup/env" # ghcup-env
export PATH=/Users/dannyramirez/.cabal/bin:/Users/dannyramirez/.ghcup/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/Library/Apple/usr/bin:/Users/dannyramirez/.cargo/bin:/Users/dannyramirez/.antigen/bundles/robbyrussell/oh-my-zsh/lib:/Users/dannyramirez/.antigen/bundles/zsh-users/zsh-syntax-highlighting:/Users/dannyramirez/.antigen/bundles/zsh-users/zsh-autosuggestions:/Users/dannyramirez/.antigen/bundles/zsh-users/zsh-completions:~/nand2tetris/tools

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/dannyramirez/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/dannyramirez/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/dannyramirez/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/dannyramirez/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# For Emacs vterm
if [ -n "$INSIDE_EMACS" ]; then
    DISABLE_AUTO_TITLE="true"
    # ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=gray,underline'

    # VTerm
    if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
        function vterm_printf(){
            if [ -n "$TMUX" ]; then
                # tell tmux to pass the escape sequences through
                # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
                printf "\ePtmux;\e\e]%s\007\e\\" "$1"
            elif [ "${TERM%%-*}" = "screen" ]; then
                # GNU screen (screen, screen-256color, screen-256color-bce)
                printf "\eP\e]%s\007\e\\" "$1"
            else
                printf "\e]%s\e\\" "$1"
            fi
        }

        function vterm_prompt_end() {
            vterm_printf "51;A$(whoami)@$(hostname):$(pwd)";
        }

        setopt PROMPT_SUBST
        PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'

        alias clear='vterm_printf "51;Evterm-clear-scrollback";tput clear'
        alias reset='vterm_printf "51;Evterm-clear-scrollback";tput clear'
    fi
fi
# Prettify ls
if (( $+commands[gls] )); then
    alias ls='gls --color=tty --group-directories-first'
else
    alias ls='ls --color=tty --group-directories-first'
fi

# Alias
alias g++='g++-11 -std=c++20'
alias cat='ccat'

# Emacs
alias me="emacs -Q -l $EMACSD/init-mini.el" # mini emacs
alias mte="emacs -Q -nw -l $EMACSD/init-mini.el" # mini terminal emacs
alias e="$EDITOR -n"
alias ec="$EDITOR -n -c"
alias ef="$EDITOR -c"
alias te="$EDITOR -nw"
alias rte="$EDITOR -e '(let ((last-nonmenu-event nil) (kill-emacs-query-functions nil)) (save-buffers-kill-emacs t))' && te"

# General
alias zshconf="$EDITOR $HOME/.zshrc"
alias h='history'
alias c='clear'
