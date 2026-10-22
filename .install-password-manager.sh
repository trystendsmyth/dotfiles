#!/bin/sh
# Runs as chezmoi's read-source-state.pre hook (secrets installs only), so `bw`
# is installed and logged in before any template calls the bitwarden function.
# Runs on every chezmoi command: keep the fast path fast.

if ! command -v bw >/dev/null 2>&1; then
    case "$(uname -s)" in
        Darwin) platform=macos ;;
        Linux)  platform=linux ;;
        *)      echo "Bitwarden CLI: unsupported OS $(uname -s)" >&2; exit 1 ;;
    esac
    case "$(uname -m)" in
        x86_64)        suffix="" ;;
        aarch64|arm64) suffix="-arm64" ;;
        *)             echo "Bitwarden CLI: no build for $(uname -m)" >&2; exit 1 ;;
    esac

    if [ "$platform" = macos ] && command -v brew >/dev/null 2>&1; then
        brew install bitwarden-cli || exit 1
    else
        # The vault URL redirects to the latest x64 zip; derive the arm64 name from it.
        url="$(curl -fsSI "https://vault.bitwarden.com/download/?app=cli&platform=$platform" \
            | sed -n 's/^[Ll]ocation: *\([^[:space:]]*\).*/\1/p')"
        [ -n "$url" ] || { echo "Bitwarden CLI: could not resolve download URL" >&2; exit 1; }
        url="$(echo "$url" | sed "s/bw-$platform-/bw-$platform$suffix-/")"

        tmp="$(mktemp -d)"
        curl -fsSL "$url" -o "$tmp/bw.zip" && unzip -oq "$tmp/bw.zip" -d "$tmp" || exit 1
        sudo mkdir -p /usr/local/bin
        sudo install -m 755 "$tmp/bw" /usr/local/bin/bw || exit 1
        rm -rf "$tmp"
    fi
fi

# Prompts for the API key client_id/secret (or reads BW_CLIENTID/BW_CLIENTSECRET).
# Unlocking is handled by chezmoi itself via bitwarden.unlock = "auto".
if bw status 2>/dev/null | grep -q '"unauthenticated"'; then
    bw login --apikey || exit 1
fi
