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
sudo_keepalive_pid=$!
nix_installer_tmp=""
brew_installer_tmp=""
cleanup() {
  kill "$sudo_keepalive_pid" 2>/dev/null || true
  if [[ -n "$nix_installer_tmp" ]]; then
    rm -f "$nix_installer_tmp"
  fi
  if [[ -n "$brew_installer_tmp" ]]; then
    rm -f "$brew_installer_tmp"
  fi
}
trap cleanup EXIT

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  printf 'Xcode Command Line Tools are required. Run xcode-select --install, finish the installer, then rerun this script.\n' >&2
  exit 1
fi

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v nix >/dev/null 2>&1; then
  nix_installer_tmp="$(mktemp)"
  /usr/bin/curl -fsSL -o "$nix_installer_tmp" https://nixos.org/nix/install
  sh "$nix_installer_tmp" --daemon
  rm -f "$nix_installer_tmp"
  nix_installer_tmp=""
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
    brew_installer_tmp="$(mktemp)"
    /usr/bin/curl -fsSL -o "$brew_installer_tmp" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    NONINTERACTIVE=1 /bin/bash "$brew_installer_tmp"
    rm -f "$brew_installer_tmp"
    brew_installer_tmp=""
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
fi

"$ROOT_DIR/scripts/apply.sh" "$role"
