#!/bin/bash

# Download dotfiles and begin installation

download_dotfiles() {
  echo "Downloading from repo..."
  # Download repo tar.gz via curl
  if [ -x "$(command -v curl)" ]; then
    curl -L https://github.com/trystendsmyth/dotfiles/archive/master.tar.gz -o "$HOME/dotfiles-master.tar.gz"
    tar xzf "$HOME/dotfiles-master.tar.gz"
    rm "$HOME/dotfiles-master.tar.gz"
    mv "$HOME/dotfiles-master" "$HOME/.dotfiles"

  # Else, download repo tar.gz via wget
  elif [ -x "$(command -v wget)" ]; then
    wget -O "$HOME/dotfiles-master.tar.gz" https://github.com/trystendsmyth/dotfiles/archive/master.tar.gz
    tar xzf "$HOME/dotfiles-master.tar.gz"
    rm "$HOME/dotfiles-master.tar.gz"
    mv "$HOME/dotfiles-master" "$HOME/.dotfiles"
  fi
}

echo "Attempting to install new dotfiles..."

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

# Verify successful download and print instructions for the user
if [ -d "$HOME/.dotfiles" ]; then
  # install Xcode and Command Line Tools
  if [[ $(xcode-select -p 2> /dev/null || true) ]]; then
    echo "Xcode command tools already installed"
  else
    while true; do
      read -p "Install (f)ull Xcode or (c)ommand tools only? " -n 1 -r fc
      echo
      case $fc in
          [Cc]* ) $(xcode-select --install); break;;
          [Ff]* ) . "$HOME/.dotfiles/install-xcode.sh" "please"; break;;
      esac
    done
  fi

  # initiate make process
  make -C "$HOME/.dotfiles" install
else
  printf "\\033[31mERROR:\\033[0m dotfiles either not downloaded or not extracted successfully\\n" >&2
  exit 1
fi
