#!/bin/bash

# install Xcode Command Line Tools
# https://github.com/timsutton/osx-vm-templates/blob/ce8df8a7468faa7c5312444ece1b977c1b2f77a4/scripts/xcode-cli-tools.sh
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
  grep "\*.*Command Line" |
  head -n 1 | awk -F"*" '{print $2}' |
  sed -e 's/^ *//' |
  tr -d '\n')
softwareupdate -i "$PROD" -v

if [ -d "$HOME/.dotfiles" ]; then
printf "\\033[31mERROR:\\033[0m ~/.dotfiles already exists on this system.\\n" >&2
exit 1
fi

# clone my dotfiles and make them
git clone git@github.com:trystendsmyth/dotfiles.git ~/.dotfiles
make -C "$HOME/.dotfiles" install
