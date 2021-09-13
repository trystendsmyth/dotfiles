# set paths
export PATH="$PATH:$HOME/bin:/usr/local/git/bin:/usr/local/bin:/usr/local/:/usr/local/sbin"

# set default editor
export EDITOR='nano'

# utf-8 all the things
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# set colors
export TERM=xterm-256color
export CLICOLOR=1
export LS_COLORS="di=1;34:ln=1;35:so=1;31:pi=1;33:ex=1;32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

# set default blocksize for ls, df, du
export BLOCKSIZE=1k

# gpg
export GPG_TTY=$(tty)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Ignores all one-word commands for more efficient bash history searching
export HISTIGNORE=?
# Long history without duplicates, flush after every command
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=1000000

# When the shell exits, append to the history file instead of overwriting it
setopt appendhistory
setopt sharehistory
setopt incappendhistory

# directory specific .envrc files
eval "$(direnv hook zsh)"

# Zsh completion for brew installed tools
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

source ~/.zsh_theme

# Aliases are managed here
source ~/.shell_aliases

# Functions are managed here
source ~/.shell_functions

. /usr/local/etc/profile.d/z.sh

# Work related additions
test -f ~/.work_profile && source ~/.work_profile