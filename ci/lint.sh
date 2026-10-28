#!/usr/bin/env bash
# Render every run_* script template for each OS / distro / install type and shellcheck the
# result, plus the plain shell scripts. Needs chezmoi and shellcheck on PATH.
set -u
cd "$(dirname "$0")/.." || exit 1
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

# name os arch id idLike
targets=(
    "ubuntu linux amd64 ubuntu debian"
    "mint linux amd64 linuxmint ubuntu_debian"
    "debian-arm linux arm64 debian _"
    "fedora linux amd64 fedora _"
    "arch linux amd64 arch _"
    "macos darwin arm64 _ _"
    "macos-intel darwin amd64 _ _"
)
for t in "${targets[@]}"; do
    read -r name os arch id like <<<"$t"
    for minimal in false true; do
        cfg="$tmp/$name-$minimal.toml"
        printf '[data]\n email="ci@example.com"\n fullname="CI"\n gituser="ci"\n minimalinstall="%s"\n workconfig="false"\n secrets="false"\n signingkey=""\n fakeos="%s"\n fakearch="%s"\n [data.fakerel]\n  id="%s"\n  idLike="%s"\n' \
            "$minimal" "$os" "$arch" "$id" "${like//_/ }" > "$cfg"
        for f in run_*.tmpl; do
            # Stand-ins for .chezmoi.os/arch/osRelease, so one machine renders every platform.
            src="$(sed -e 's/\.chezmoi\.osRelease/.fakerel/g' -e 's/\.chezmoi\.os/.fakeos/g' \
                -e 's/\.chezmoi\.arch/.fakearch/g' "$f")"
            out="$tmp/$name-$minimal-$f.sh"
            if ! chezmoi --config "$cfg" --source "$tmp" execute-template "$src" > "$out"; then
                echo "RENDER FAILED: $f ($name, minimal=$minimal)"; fail=1; continue
            fi
            # Scripts for other platforms render to just the shebang.
            [ "$(grep -cv '^\s*$' "$out")" -le 1 ] && continue
            if ! shellcheck -s bash -S warning "$out" > "$out.log"; then
                echo "SHELLCHECK: $f ($name, minimal=$minimal)"
                sed "s#$out#$f#" "$out.log"; fail=1
            fi
        done
    done
done

shellcheck -s sh -S warning .install-password-manager.sh bin/executable_tmux-copy || fail=1
shellcheck -s bash -S warning dot_config/starship/prompt-state.sh ci/*.sh || fail=1

[ $fail = 0 ] && echo "lint: all clean"
exit $fail
