#!/bin/bash

# Download dotfiles and begin installation

main() {
  info "Attempting to install Xcode command tools" && install_xcode
  info "Attempting to install new dotfiles..." && check_dotfiles

  # Verify successful download and make
  if [ -d "$HOME/.dotfiles" ]; then
    ask_for_sudo
    make -C "$HOME/.dotfiles" install
  else
    error "\\033[31mERROR:\\033[0m dotfiles either not downloaded or not extracted successfully\\n" >&2
    exit 1
  fi
}

function ask_for_sudo() {
    info "Prompting for sudo password"
    if sudo --validate; then
        # Keep-alive
        while true; do sudo --non-interactive true; \
            sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        success "Sudo credentials updated"
    else
        error "Obtaining sudo credentials failed"
        exit 1
    fi
}

function install_xcode() {
  if [[ $(xcode-select -p 2> /dev/null || true) ]]; then
    warn "Xcode command tools already installed"
  else
    info "Installing Xcode command tools..."
    # https://github.com/timsutton/osx-vm-templates/blob/ce8df8a7468faa7c5312444ece1b977c1b2f77a4/scripts/xcode-cli-tools.sh
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
    PROD=$(softwareupdate -l |
      grep "\*.*Command Line" |
      head -n 1 | awk -F"*" '{print $2}' |
      sed -e 's/^ *//' |
      tr -d '\n')
    softwareupdate -i "$PROD" --verbose;
    success "Xcode command tools installed"
  fi
}

function check_dotfiles() {
  if [ -d "$HOME/.dotfiles" ]; then
    read -p "Dotfiles already exists on this system. Overwrite? (y/n)" -n 1 -s -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]
    then
        rm -rf "$HOME/.dotfiles"
        download_dotfiles
    fi
  else
    download_dotfiles
  fi
}

function download_dotfiles() {
  info "Downloading from repo..."
  # If git isn't installed
  if ! [ -x "$(command -v git)" ]; then
    # Download repo tar.gz via curl
    if [ -x "$(command -v curl)" ]; then
      curl -L https://github.com/trystendsmyth/dotfiles/archive/master.tar.gz -o "$HOME/dotfiles-master.tar.gz"
      tar xzf "$HOME/dotfiles-master.tar.gz"
      rm "$HOME/dotfiles-master.tar.gz"
      mv "$HOME/dotfiles-master" "$HOME/.dotfiles"
      success "Dotfiles downloaded via CURL"

    # Else, download repo tar.gz via wget
    elif [ -x "$(command -v wget)" ]; then
      wget -O "$HOME/dotfiles-master.tar.gz" https://github.com/trystendsmyth/dotfiles/archive/master.tar.gz
      tar xzf "$HOME/dotfiles-master.tar.gz"
      rm "$HOME/dotfiles-master.tar.gz"
      mv "$HOME/dotfiles-master" "$HOME/.dotfiles"
      success "Dotfiles downloaded via WGET"
    fi
  else
    git clone --recursive https://github.com/trystendsmyth/dotfiles.git "$HOME/.dotfiles"
    success "Dotfiles cloned via GIT"
  fi
}

# Credit: https://github.com/Sajjadhosn/dotfiles/

function coloredEcho() {
    local exp="$1";
    local color="$2";
    local arrow="$3";
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput bold;
    tput setaf "$color";
    echo "$arrow $exp";
    tput sgr0;
}

function info() {
    coloredEcho "$1" blue "===>"
}

function success() {
    coloredEcho "$1" green "===>"
}

function warn() {
    coloredEcho "$1" yellow "===>"
}

function error() {
    coloredEcho "$1" red "===>"
}

main "$@"
