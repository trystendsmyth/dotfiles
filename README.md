# .dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A collection of files for automated setup, configuration and software installation on a new MacOS, Linux or Windows machine.
<br/><br/>
## MacOS installation
***
Open Terminal and on a fresh install, run:

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/trystendsmyth/dotfiles/master/install.sh)"

If you have `Xcode CLI tools` installed already, you can just use:

    sh -c "$(curl -fsSL git.io/chezmoi)" -- init --apply trystendsmyth
## Linux installation
***

    sh -c "$(wget -qO- git.io/chezmoi)" -- init --apply trystendsmyth

To install and remove the installer use `--one-shot` instead of `--apply`
<br/><br/>
## Windows installation
***
**Windows does not use Chezmoi and instead uses Boxstarter with Chocolatey.**

Run the following from an **elevated** command-prompt:

    start http://boxstarter.org/package/url?https://raw.githubusercontent.com/trystendsmyth/dotfiles/master/install.ps1