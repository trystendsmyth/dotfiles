#!/usr/bin/env bash
# Post-install checks, run by CI as the user `chezmoi init --apply` set up.
# The idempotence check runs last, so it also catches tools that rewrite managed files.
set -u
fail=0
pass() { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
skip() { printf '  skip  %s\n' "$1"; }
check() {
    local name=$1; shift
    if "$@"; then pass "$name"; else bad "$name"; fi
}

# The environment a new login session gets (PATH: ~/bin for chezmoi, Linuxbrew, ...).
# shellcheck disable=SC1090
. ~/.profile
export TERM=xterm-256color
os=$(uname -s)
minimal=$(chezmoi execute-template '{{ .minimalinstall }}')
err=$(mktemp)
echo "== $(uname -sm), minimal install: $minimal"

# Interactive shells want a terminal; without `script` the shell checks below would prove nothing.
command -v script >/dev/null || { echo "FAIL: \`script\` (util-linux / bsdutils) is needed to run shells in a pty"; exit 1; }
in_pty() {
    if [ "$os" = Darwin ]; then
        script -q /dev/null "$@"
    else
        script -qec "$(printf '%q ' "$@")" /dev/null
    fi
}

echo "-- shells"
out=$(mktemp)
for sh in zsh bash; do
    # (`-c exit` would make bash print "exit" to stderr)
    in_pty "$sh" -i -c true >/dev/null 2>&1  # first start may set things up (zsh-nvm installs nvm)
    in_pty sh -c "$sh -i -c true 2>'$err'" >/dev/null
    if [ ! -s "$err" ]; then pass "$sh -i starts with nothing on stderr"
    else bad "$sh -i starts with nothing on stderr:"; sed 's/^/        /' "$err"; fi
done

echo "-- starship"
check "starship --version" starship --version
in_pty sh -c "zsh -i -c '_sp_precmd; starship prompt' >'$out' 2>'$err'" >/dev/null
if [ -s "$out" ] && [ ! -s "$err" ] && grep -q "$USER" "$out"; then
    pass "starship prints the prompt (with user@host) and no warnings"
else
    bad "starship prompt (stdout, then stderr):"; head -c 600 "$out" | cat -v | sed 's/^/        /'; sed 's/^/        /' "$err"
fi

echo "-- tmux"
if [ -f ~/.tmux.conf ]; then
    # tmux reports config errors as messages but still exits 0, so any output is a failure
    tmux_out=$(tmux -L ci -f ~/.tmux.conf new-session -d -s ci 2>&1 &&
        tmux -L ci source-file -n ~/.tmux.conf 2>&1; tmux -L ci kill-server 2>&1)
    if [ -z "$tmux_out" ]; then pass "tmux loads ~/.tmux.conf without errors"
    else bad "tmux loads ~/.tmux.conf without errors:"; printf '%s\n' "$tmux_out" | sed 's/^/        /'; fi
else
    skip "tmux (~/.tmux.conf not installed: minimal install)"
fi

echo "-- neovim"
if command -v nvim >/dev/null; then
    nvim_version=$(nvim --version | sed -n '1s/^NVIM v//p')
    check "nvim $nvim_version >= 0.11.2 (LazyVim minimum)" \
        test "$(printf '%s\n' 0.11.2 "$nvim_version" | sort -V | head -n1)" = 0.11.2
    # restore installs the plugin versions in lazy-lock.json (sync would update the lockfile)
    check "LazyVim installs its plugins headless" nvim --headless "+Lazy! restore" +qa
else
    skip "neovim (not installed: minimal macOS install)"
fi

echo "-- nvm"
if [ -d ~/.nvm/versions/node ]; then
    node_path=$(zsh -i -c 'node -e "console.log(process.execPath)"' 2>/dev/null | tail -n1)
    check "node in zsh comes from nvm ($node_path)" test "${node_path#"$HOME"/.nvm/}" != "$node_path"
else
    skip "node (nvm installs no Node on minimal macOS installs)"
fi

echo "-- core tools"
tools=(fzf eza bat fd delta starship)
if [ "$os" = Linux ] || [ "$minimal" = false ]; then
    tools+=(zoxide rg lazygit tmux nvim tree-sitter)
fi
has() { command -v "$1" >/dev/null; }
for t in "${tools[@]}"; do check "$t" has "$t"; done

echo "-- chezmoi"
check "chezmoi verify" chezmoi verify --exclude=scripts
diff_out=$(chezmoi diff --exclude=scripts)
if [ -z "$diff_out" ]; then pass "second apply would change nothing (chezmoi diff is empty)"
else bad "chezmoi diff is not empty:"; printf '%s\n' "$diff_out" | head -60 | sed 's/^/        /'; fi

rm -f "$err" "$out"
exit $fail
