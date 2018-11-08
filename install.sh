#!/bin/bash

echo Attempting to install dotfiles...

# install Xcode Command Line Tools
# https://github.com/timsutton/osx-vm-templates/blob/ce8df8a7468faa7c5312444ece1b977c1b2f77a4/scripts/xcode-cli-tools.sh
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
  grep "\*.*Command Line" |
  head -n 1 | awk -F"*" '{print $2}' |
  sed -e 's/^ *//' |
  tr -d '\n')
softwareupdate -i "$PROD" --verbose;

if [ -d "$HOME/.dotfiles" ]; then
printf "\\033[31mERROR:\\033[0m ~/.dotfiles already exists on this system.\\n" >&2
exit 1
fi

# If git isn't installed
if ! [ -x "$(command -v git)" ]; then

# Download repo tar.gz via curl
if [ -x "$(command -v curl)" ]; then
  curl -L https://github.com/trystendsmyth/dotfiles/archive/master.tar.gz -o "$HOME/dotfiles-master.tar.gz"
  tar xzf "$HOME/dotfiles-master.tar.gz"
  mv "$HOME/dotfiles-master" "$HOME/.dotfiles"

# Else, download repo tar.gz via wget
elif [ -x "$(command -v wget)" ]; then
  wget -O "$HOME/dotfiles-master.tar.gz" https://github.com/trystendsmyth/dotfiles/archive/master.tar.gz
  tar xzf "$HOME/dotfiles-master.tar.gz"
  mv "$HOME/dotfiles-master" "$HOME/.dotfiles"
fi

# Else, clone the dotfiles repo via git
else
git clone --recursive https://github.com/trystendsmyth/dotfiles.git "$HOME/.dotfiles"
fi

# Verify successful download and print instructions for the user
if [ -d "$HOME/.dotfiles" ]; then
make -C "$HOME/.dotfiles" install
else
printf "\\033[31mERROR:\\033[0m dotfiles either not downloaded or not extracted successfully\\n" >&2
exit 1
fi
