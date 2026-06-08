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
trap 'kill "$sudo_keepalive_pid" 2>/dev/null || true' EXIT

if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew is required. Run ./scripts/bootstrap.sh %s first.\n' "$role" >&2
    exit 1
  fi
fi

if ! command -v nix >/dev/null 2>&1; then
  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

if ! command -v nix >/dev/null 2>&1; then
  printf 'Nix is required. Run ./scripts/bootstrap.sh %s first.\n' "$role" >&2
  exit 1
fi

cd "$ROOT_DIR"

brew bundle --file "$ROOT_DIR/Brewfile.common"
brew bundle --file "$ROOT_DIR/Brewfile.$role"

if command -v darwin-rebuild >/dev/null 2>&1; then
  sudo darwin-rebuild switch --flake "$ROOT_DIR#$role"
else
  sudo nix --extra-experimental-features "nix-command flakes" \
    run nix-darwin/master#darwin-rebuild -- \
    switch --flake "$ROOT_DIR#$role"
fi
