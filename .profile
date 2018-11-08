# set paths
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:/usr/local/bin/"
export PATH="/usr/local/git/bin:/usr/local/bin:/usr/local/:/usr/local/sbin:$PATH"

# set default editor
export EDITOR='nano'

# utf-8 all the things
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# change prompt
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "

# set colors
export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# set default blocksize for ls, df, du
export BLOCKSIZE=1k

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Ignores all one-word commands for more efficient bash history searching
export HISTIGNORE=?
# Long history without duplicates, flush after every command
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=1000000

# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend

# directory specific .envrc files
eval "$(direnv hook bash)"

# Bash completion for brew installed tools
source "$(brew --prefix)/etc/bash_completion"

# Aliases are managed here
source ~/.bash_aliases

# Functions are managed here
source ~/.bash_functions
