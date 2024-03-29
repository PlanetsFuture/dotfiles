#!/bin/sh

# Variables
DOTFILES = $HOME/.dotfiles
EMACSD=$HOME/danny-emacs

# Get OS information
OS=`uname -s`
OSREV=`uname -r`
OSARCH=`uname -m`

# Use colors
if command -v tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

# Functions
is_mac()
{
    [ "$OS" = "Darwin" ]
}

is_cygwin()
{
    [ "$OSTYPE" = "cygwin" ]
}

is_linux()
{
    [ "$OS" = "Linux" ]
}

is_debian() {
    command -v apt-get >/dev/null 2>&1
}

is_arch() {
    command -v yay >/dev/null 2>&1 || command -v pacman >/dev/null 2>&1
}

sync_repo() {
    local repo_uri="$1"
    local repo_path="$2"
    local repo_branch="$3"

    if [ -z "$repo_branch" ]; then
        repo_branch="master"
    fi

    if [ ! -e "$repo_path" ]; then
        mkdir -p "$repo_path"
        git clone --depth 1 --branch $repo_branch "https://github.com/$repo_uri.git" "$repo_path"
    else
        cd "$repo_path" && git pull --rebase --stat origin $repo_branch; cd - >/dev/null
    fi
}

install_package() {
    if ! command -v ${1} >/dev/null 2>&1; then
        if is_mac; then
            brew install ${1}
        elif is_debian; then
            sudo apt-get install -y ${1}
        elif is_arch; then
            pacman -Ssu --noconfirm ${1}
        elif is_cygwin; then
            apt-cyg install -y ${1}
        fi
    else
        if is_mac; then
            brew upgrade ${1}
        elif is_debian; then
            sudo apt-get upgrade -y ${1}
        elif is_arch; then
            pacman -Ssu --noconfirm ${1}
        elif is_cygwin; then
            apt-cyg upgrade -y ${1}
        fi
    fi
}

clean_dotfiles() {
    confs="
    .gitconfig
    .npmrc
    .vimrc
    .zshenv
    .zshrc
    .zshrc.local
    "
    for c in ${confs}; do
        [ -f $HOME/${c} ] && mv $HOME/${c} $HOME/${c}.bak
    done

    [ -d $EMACSD ] && mv $EMACSD $EMACSD.bak

    rm -rf $ZSH $DOTFILES

    rm -f $HOME/.gitignore_global $HOME/.gitconfig_global

}

YES=0
NO=1
promote_yn() {
    eval ${2}=$NO
    read -p "$1 [y/N]: " yn
    case $yn in
        [Yy]* )    eval ${2}=$YES;;
        [Nn]*|'' ) eval ${2}=$NO;;
        *)         eval ${2}=$NO;;
    esac
}

# Clean or not?
if [ -d $ZSH ] || [ -d $EMACSD ]; then
    promote_yn "Do you want to reset all configurations?" "continue"
    if [ $continue -eq $YES ]; then
        clean_dotfiles
    fi
fi

# Install Brew/apt-cyg
if is_mac && ! command -v brew >/dev/null 2>&1; then
    printf "${GREEN}▓▒░ Installing Homebrew...${NORMAL}\n"
    # Install homebrew

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Tap cask and cask-upgrade
    brew tap homebrew/cask
    brew tap homebrew/cask-versions
    brew tap homebrew/cask-fonts
    brew tap buo/cask-upgrade

    # Install GNU utilities
    brew install coreutils
elif is_cygwin && ! command -v apt-cyg >/dev/null 2>&1; then
    printf "${GREEN}▓▒░ Installing Apt-Cyg...${NORMAL}\n"
    APT_CYG=/usr/local/bin/apt-cyg
    curl -fsSL https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg > $APT_CYG
    chmod +x $APT_CYG
fi

# Check git
if ! command -v git >/dev/null 2>&1; then
    install_package git
fi

# Check curl
if ! command -v curl >/dev/null 2>&1; then
    install_package curl
fi

# Check zsh
if ! command -v zsh >/dev/null 2>&1; then
    install_package zsh
fi

if is_mac && ! command -v tree >/dev/null 2>&1; then
    install_package tree
fi

# Dotfiles
printf "${GREEN}▓▒░ Installing Dotfiles...${NORMAL}\n"
sync_repo PlanetsFuture/dotfiles $DOTFILES

chmod +x $DOTFILES/install.sh

ln -sf $DOTFILES/.zshenv $HOME/.zshenv
ln -sf $DOTFILES/.zshrc $HOME/.zshrc
ln -sf $DOTFILES/.zprofile $HOME/.zprofile
ln -sf $DOTFILES/.vimrc $HOME/.vimrc
ln -sf $DOTFILES/.alacritty.yml
cp -n $DOTFILES/.npmrc $HOME/.npmrc
cp -n $DOTFILES/.gemrc $HOME/.gemrc

mkdir -p $HOME/.cargo && cp -n $DOTFILES/cargo.config $HOME/.cargo/config
cp -n $DOTFILES/.zshrc.local $HOME/.zshrc.local
mkdir -p $HOME/.pip; cp -n $DOTFILES/.pip.conf $HOME/.pip/pip.conf

ln -sf $DOTFILES/.gitignore_global $HOME/.gitignore_global
ln -sf $DOTFILES/.gitconfig_global $HOME/.gitconfig_global
if is_mac; then
    cp -n $DOTFILES/.gitconfig_macOS $HOME/.gitconfig
elif is_cygwin; then
    cp -n $DOTFILES/.gitconfig_cygwin $HOME/.gitconfig
else
    cp -n $DOTFILES/.gitconfig_linux $HOME/.gitconfig
fi

if is_cygwin; then
    ln -sf $DOTFILES/.minttyrc $HOME/.minttyrc
fi

# Emacs Configurations
printf "${GREEN}▓▒░ Installing Danny Emacs...${NORMAL}\n"
sync_repo PlanetsFuture/danny-emacs $EMACSD

# Entering zsh
printf "Done. Enjoy!\n"
if command -v zsh >/dev/null 2>&1; then
    if is_cygwin && [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s $(which zsh)
        printf "${GREEN} You need to logout and login to enable zsh as the default shell.${NORMAL}\n"
    fi
    env zsh
else
    echo "${RED}Error: zsh is not installed${NORMAL}" >&2
    exit 1
fi
