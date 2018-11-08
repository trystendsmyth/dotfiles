# .dotfiles

A collection of files for automated setup, configuration and software installation on a new MacOS install.

## installation
On a new mac, open a Terminal and run:

    curl -O https://raw.githubusercontent.com/trystendsmyth/dotfiles/master/bootstrap.sh
    chmod +x bootstrap.sh
    ./bootstrap.sh

##maintenance
Enter the `~/dotfiles` directory, make changes and `make` it:

    cd ~/dotfiles
    make

The Makefile contains sections for specific commands.

##credits

This is mostly a shameless mashup of the following work :

* https://github.com/Overbryd/dotfiles
* https://github.com/mihaliak/dotfiles
* https://github.com/mattorb/dotfiles
