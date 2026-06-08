#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  printf 'Usage: %s home|work\n' "$0" >&2
}

role="${1:-}"
case "$role" in
  home | work) ;;
  *)
    usage
    exit 1
    ;;
esac

sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  printf 'Xcode Command Line Tools are required. Run xcode-select --install, finish the installer, then rerun this script.\n' >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  sh <(/usr/bin/curl -L https://nixos.org/nix/install) --daemon
fi

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    NONINTERACTIVE=1 /bin/bash -c "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
fi

"$ROOT_DIR/scripts/apply.sh" "$role"
