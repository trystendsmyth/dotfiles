#!/bin/bash
echo "Checking Xcode CLI tools..."
xcode-select -p &> /dev/null
if [ $? -ne 0 ]; then
  echo "Xcode CLI tools not found. Installing them..."
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l |
    grep "\*.*Command Line" |
    tail -n 1 | sed 's/^[^C]* //')
  softwareupdate -i "$PROD" --verbose;
else
  echo "Xcode CLI tools OK!"
fi

echo "Launching Chezmoi install..."
sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply trystendsmyth