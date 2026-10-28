# .dotfiles

[![CI](https://github.com/trystendsmyth/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/trystendsmyth/dotfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A collection of files for automated setup, configuration and software installation on a new MacOS, Linux or Windows machine.
<br/><br/>
## MacOS installation
***
Open Terminal and on a fresh install, run:

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/trystendsmyth/dotfiles/master/install.sh)"

If you have `Xcode CLI tools` installed already, you can just use:

    sh -c "$(curl -fsSL get.chezmoi.io)" -- init --apply trystendsmyth
## Linux installation
***

    sh -c "$(wget -qO- get.chezmoi.io)" -- init --apply trystendsmyth

To install and remove the installer use `--one-shot` instead of `--apply`
<br/><br/>
## Windows installation
***
**Windows does not use Chezmoi and instead uses Boxstarter with Chocolatey.**

Run the following from an **elevated** command-prompt:

    start http://boxstarter.org/package/url?https://raw.githubusercontent.com/trystendsmyth/dotfiles/master/install.ps1
<br/><br/>
## Shell prompt
***
zsh and bash share one [Starship](https://starship.rs) prompt, `~/.config/starship.toml`, styled after the
earlier powerlevel10k theme. Starship styles are fixed, but the rounded segment caps take their colours
from both neighbouring segments, so `~/.config/starship/prompt-state.sh` works out before each prompt which
segment variants are visible (directory, git state, duration, jobs, Node version) and exports them for
Starship's `env_var` modules. Inside a git repository it runs one `git status` per prompt.

oh-my-zsh still provides the zsh plugins. PowerShell can use the same `starship.toml`; Windows isn't set up
for it. Remote [xxh](https://github.com/xxh/xxh) sessions keep the self-contained powerlevel10k plugin,
since the only Starship plugin for xxh is unmaintained.

Profile zsh startup with `ZSH_PROFILE=1 zsh -i -c exit`.
<br/><br/>
## Neovim
***
`~/.config/nvim` is a [LazyVim](https://www.lazyvim.org) setup with the TypeScript, JSON, YAML, Markdown,
Tailwind, Docker, Python, Go and Rust extras, ESLint and Prettier. Plugins install on first launch; Mason
installs the language servers. LazyVim needs Neovim 0.11.2 or newer and the tree-sitter CLI, which the
Linux install takes from the upstream releases when the distro's packages are older.

`lazy-lock.json` pins plugin versions. After `:Lazy update`, save the new versions back to this repo:

    chezmoi re-add ~/.config/nvim/lazy-lock.json
<br/><br/>
## tmux
***
Copy mode's `y` and `Enter` copy to the system clipboard: `pbcopy` on macOS, and `~/bin/tmux-copy` on Linux,
which uses `wl-copy` in Wayland sessions and `xclip` in X11. tmux also sends copies to the terminal with
OSC 52, so a copy in tmux over SSH reaches the local clipboard (kitty supports it).
<br/><br/>
## CI
***
[GitHub Actions](.github/workflows/ci.yml) runs `chezmoi init --apply` of the checked-out branch, then
[`ci/verify.sh`](ci/verify.sh), on:
- Linux containers: Ubuntu 24.04, Linux Mint 22, Fedora and Arch, as full and minimal installs.
- macOS, as a minimal install.

It also shellchecks every install script as rendered for each platform ([`ci/lint.sh`](ci/lint.sh)), and
runs weekly to catch upstream changes. CI skips Homebrew on Linux, Homebrew casks and `brew upgrade` on
macOS, and the Tailscale service where there's no systemd. `install.ps1` (Windows) isn't tested.
