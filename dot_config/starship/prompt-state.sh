# Per-prompt state for ~/.config/starship.toml, which recreates the old powerlevel10k look.
#
# The powerline caps between segments take their colours from both neighbours, and Starship
# styles are static. So before each prompt this exports one _SP_* variable per segment variant
# that should be visible, and starship.toml draws each variant with an env_var module.
# Shell builtins only, plus one `git status` inside a repository.
#
# Sourced by ~/.zsh_theme and ~/.bashrc. POSIX sh plus `local`.

_SP_I_BRANCH=$'\uF126'
_SP_I_COMMIT=$'\uE729'     # detached HEAD
_SP_I_REMOTE=$'\uE728'     # remote branch, when its name differs
_SP_I_STAGED=$'\uF055'
_SP_I_UNSTAGED=$'\uF06A'
_SP_I_UNTRACKED=$'\uF059'
_SP_I_BEHIND=$'\uF01A'
_SP_I_AHEAD=$'\uF01B'
_SP_I_STASH=$'\uF01C'
_SP_I_JOBS=$'\uF013'
_SP_VARS=
_SP_LAST_STATUS=0

_sp_set() {
    export "$1=$2"
    _SP_VARS="$_SP_VARS $1"
}

# _sp_pad2 N: two-digit N in _sp_r
_sp_pad2() {
    case $1 in ?) _sp_r=0$1 ;; *) _sp_r=$1 ;; esac
}

# _sp_vgt A B: true if version A > B (dotted numbers)
_sp_vgt() {
    local a="$1." b="$2." x y
    while [ -n "$a$b" ]; do
        x=${a%%.*}; y=${b%%.*}
        a=${a#*.}; b=${b#*.}
        [ "${x:-0}" -gt "${y:-0}" ] 2>/dev/null && return 0
        [ "${x:-0}" -lt "${y:-0}" ] 2>/dev/null && return 1
    done
    return 1
}

# _sp_nvm_default: nvm's default alias resolved to an installed version (no "v"), or "system"
_sp_nvm_default() {
    local def='' n=0 best='' p v
    [ -r "$NVM_DIR/alias/default" ] && read -r def < "$NVM_DIR/alias/default"
    while [ -n "$def" ] && [ -r "$NVM_DIR/alias/$def" ] && [ $n -lt 5 ]; do
        read -r def < "$NVM_DIR/alias/$def"; n=$((n + 1))
    done
    case $def in
        system) _sp_r=system; return ;;
        node|stable|"") def='' ;;
    esac
    def=${def#v}
    for p in "$NVM_DIR"/versions/node/v*; do
        [ -d "$p" ] || continue
        v=${p##*/v}
        if [ -z "$def" ] || [ "$v" = "$def" ] || case $v in "$def".*) true ;; *) false ;; esac; then
            if [ -z "$best" ] || _sp_vgt "$v" "$best"; then best=$v; fi
        fi
    done
    _sp_r=${best:-system}
}

# _sp_git: sets _sp_gitbg and _sp_gitc (segment content) when $PWD is in a git work tree
_sp_git() {
    local d="$PWD" gitdir='' line out head='' oid='' up='' ahead=0 behind=0 stash=0 \
        staged=0 unstaged=0 untracked=0 xy action='' rb c
    _sp_gitbg=
    while :; do
        if [ -d "$d/.git" ]; then gitdir="$d/.git"; break; fi
        if [ -f "$d/.git" ]; then
            read -r line < "$d/.git"; gitdir=${line#gitdir: }
            case $gitdir in /*) ;; *) gitdir="$d/$gitdir" ;; esac
            break
        fi
        [ -z "$d" ] && return
        d=${d%/*}
    done
    # --show-stash needs git 2.35+.
    out=$(git --no-optional-locks status --porcelain=v2 --branch --show-stash 2>/dev/null) ||
        out=$(git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null) || return
    # Headers come first; stop reading entries once both staged and unstaged are known.
    while IFS= read -r line; do
        case $line in
            "# branch.oid "*) oid=${line#"# branch.oid "} ;;
            "# branch.head "*) head=${line#"# branch.head "} ;;
            "# branch.upstream "*) up=${line#"# branch.upstream "} ;;
            "# branch.ab "*)
                line=${line#"# branch.ab +"}
                ahead=${line%% *}; behind=${line#* -} ;;
            "# stash "*) stash=${line#"# stash "} ;;
            "1 "*|"2 "*)
                xy=${line#? }; xy=${xy%% *}
                case $xy in .?) ;; *) staged=1 ;; esac
                case $xy in ?.) ;; *) unstaged=1 ;; esac ;;
            "u "*) unstaged=1 ;;
            *) break ;;
        esac
        [ $staged = 1 ] && [ $unstaged = 1 ] && break
    done <<EOF
$out
EOF
    case $out in "? "*|*"
? "*) untracked=1 ;; esac
    # Modified (staged or unstaged) beats untracked, as in p10k.
    if [ $staged = 1 ] || [ $unstaged = 1 ]; then _sp_gitbg=178
    elif [ $untracked = 1 ]; then _sp_gitbg=165
    else _sp_gitbg=36
    fi

    if [ "$head" = "(detached)" ]; then
        c="$_SP_I_COMMIT ${oid%"${oid#????????}"}"
    else
        c="$_SP_I_BRANCH $head"
    fi
    if [ -d "$gitdir/rebase-merge" ]; then
        if [ -f "$gitdir/rebase-merge/interactive" ]; then action=rebase-i; else action=rebase-m; fi
    elif [ -d "$gitdir/rebase-apply" ]; then
        if [ -f "$gitdir/rebase-apply/rebasing" ]; then action=rebase
        elif [ -f "$gitdir/rebase-apply/applying" ]; then action=am
        else action=am/rebase; fi
    elif [ -f "$gitdir/MERGE_HEAD" ]; then action=merge
    elif [ -f "$gitdir/CHERRY_PICK_HEAD" ]; then action=cherry-pick
    elif [ -f "$gitdir/REVERT_HEAD" ]; then action=revert
    elif [ -f "$gitdir/BISECT_LOG" ]; then action=bisect
    fi
    if [ -n "$action" ]; then
        c="$c | $action"
    else
        rb=${up#*/}
        if [ -n "$up" ] && [ "$rb" != "$head" ]; then c="$c $_SP_I_REMOTE $rb"; fi
        [ $staged = 1 ] && c="$c $_SP_I_STAGED "
        [ $unstaged = 1 ] && c="$c $_SP_I_UNSTAGED "
        [ $untracked = 1 ] && c="$c $_SP_I_UNTRACKED "
        [ "${behind:-0}" -gt 0 ] 2>/dev/null && c="$c $_SP_I_BEHIND $behind"
        [ "${ahead:-0}" -gt 0 ] 2>/dev/null && c="$c $_SP_I_AHEAD $ahead"
        [ "${stash:-0}" -gt 0 ] 2>/dev/null && c="$c $_SP_I_STASH $stash"
    fi
    _sp_gitc=$c
}

# _sp_prompt_state DURATION_MS JOBS STATUS
_sp_prompt_state() {
    [ -n "$ZSH_VERSION" ] && emulate -L sh
    local dur="$1" jobs="${2:-0}" st="$3" v prev cb db dir rest n kind d text
    for v in $_SP_VARS; do unset "$v"; done
    _SP_VARS=

    ##### left: os | root | context | lock | dir | git
    if [ "${EUID:-1}" = 0 ]; then _sp_set _SP_ROOT 1; prev=0; else prev=32; fi
    if [ -n "$SSH_CONNECTION$SSH_CLIENT$SSH_TTY" ]; then cb=0; _sp_set _SP_SSH 1; else cb=236; fi
    v=${HOSTNAME:-$HOST}
    _sp_set "_SP_CTX_${prev}_${cb}" "${USER:-$LOGNAME}"
    _sp_set "_SP_HOST_${cb}" "${v%%.*}"

    dir=$PWD
    case $dir in
        "$HOME") dir="~" ;;
        "$HOME"/*) dir="~${dir#"$HOME"}" ;;
    esac
    # More than 5 parts (counting ~): "…/" and the last 5.
    rest=${dir#/}; n=1; d=$rest
    while case $d in */*) true ;; *) false ;; esac; do d=${d#*/}; n=$((n + 1)); done
    if [ -n "$rest" ] && [ $n -gt 5 ]; then
        while [ $n -gt 5 ]; do rest=${rest#*/}; n=$((n - 1)); done
        dir="…/$rest"
    fi
    if [ ! -w "$PWD" ]; then
        _sp_set "_SP_RO_${cb}" 1; _sp_set _SP_DIR_RO "$dir"; db=4
    else
        if [ "$PWD" = "$HOME" ]; then kind=HOME; db=208
        elif case "$PWD/" in "$HOME"/*) true ;; *) false ;; esac; then kind=SUB; db=32
        else kind=OTHER; db=32
        fi
        _sp_set "_SP_DIR_${cb}_${kind}" "$dir"
    fi

    _sp_git
    if [ -n "$_sp_gitbg" ]; then
        _sp_set "_SP_GIT_${db}_${_sp_gitbg}" "$_sp_gitc"
    else
        _sp_set "_SP_END_${db}" 1
    fi

    ##### right: duration | jobs | status | node | time | ssh
    prev=NONE
    if [ -n "$dur" ] && [ "$dur" -ge 3000 ] 2>/dev/null; then
        if [ "$dur" -lt 60000 ]; then
            d=$(( (dur + 5) / 10 )); _sp_pad2 $((d % 100))
            text="$((d / 100)).${_sp_r}s"
        else
            d=$(( (dur + 500) / 1000 )); _sp_pad2 $((d % 60)); text=$_sp_r
            _sp_pad2 $((d / 60 % 60)); text="$_sp_r:$text"
            if [ $d -ge 36000 ]; then text="$((d / 3600)):$text"
            elif [ $d -ge 3600 ]; then text="0$((d / 3600)):$text"
            fi
        fi
        _sp_set _SP_DUR "$text"; prev=32
    fi
    if [ "$jobs" -gt 0 ] 2>/dev/null; then
        if [ "$jobs" -gt 1 ]; then text="$jobs $_SP_I_JOBS"; else text=$_SP_I_JOBS; fi
        if [ $prev = 32 ]; then _sp_set _SP_JOBS_32 "$text"; else _sp_set _SP_JOBS_NONE "$text"; fi
        prev=32
    fi
    # An empty command line keeps the previous status, as p10k does.
    [ -n "$st" ] && _SP_LAST_STATUS=$st
    if [ "$_SP_LAST_STATUS" = 0 ]; then _sp_set "_SP_OK_$prev" 1; else _sp_set "_SP_ERR_$prev" 1; fi

    # nvm's version, hidden when it is nvm's default (p10k's nvm segment).
    if [ -n "$NVM_DIR" ] && [ -d "$NVM_DIR" ]; then
        v=system
        case ":$PATH:" in
            *":$NVM_DIR/versions/node/v"*) v=${PATH#*"$NVM_DIR/versions/node/v"}; v=${v%%/*} ;;
        esac
        _sp_nvm_default
        if [ "$v" != "$_sp_r" ]; then _sp_set _SP_NODE "$v"; else _sp_set _SP_NO_NODE 1; fi
    else
        _sp_set _SP_NO_NODE 1
    fi
}
