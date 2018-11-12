alias cp='cp -iv'                           # Preferred 'cp' implementation
alias mv='mv -iv'                           # Preferred 'mv' implementation
alias mkdir='mkdir -pv'                     # Preferred 'mkdir' implementation
alias ll='ls -FGlAhp'                       # Preferred 'ls' implementation
alias less='less -FSRXc'                    # Preferred 'less' implementation
alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias ~="cd ~"                              # ~: Go Home
alias c='clear'                             # c: Clear terminal display
alias f='open -a Finder ./'                 # f: Opens current directory in MacOS Finder
# lr:  Full Recursive Directory Listing
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'
alias ttop="top -R -F -s 10 -o rsize" # ttop:  Recommended 'top' invocation to minimize resources
# nice directory tree listing showing permissions, user, group and size (human readable)
alias t="tree -L 1 --dirsfirst -shugp"
alias tt="tree -L 2 --dirsfirst"            # nice directory tree listing, but just 2 levels

# if we are in a tmate session, alias tmux as tmate
if [[ $TMUX =~ tmate ]]; then alias tmux=tmate; fi
