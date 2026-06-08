#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "Brewfile.common"
  "Brewfile.home"
  "Brewfile.work"
  "flake.nix"
  "modules/darwin/common.nix"
  "modules/darwin/home.nix"
  "modules/darwin/work.nix"
  "modules/home/common.nix"
  "modules/home/home.nix"
  "modules/home/work.nix"
  "scripts/apply.sh"
  "scripts/bootstrap.sh"
)

obsolete_files=(
  "playbook.yml"
  "galaxy-roles.yml"
  "local"
  "run.sh"
  "files/.zshrc_home"
  "files/.zshrc_work"
  "files/macos-settings.sh"
  "files/paths"
)

fail=0

for file in "${required_files[@]}"; do
  if [[ ! -f "$ROOT_DIR/$file" ]]; then
    printf 'missing required file: %s\n' "$file" >&2
    fail=1
  fi
done

for file in "${obsolete_files[@]}"; do
  if [[ -e "$ROOT_DIR/$file" ]]; then
    printf 'obsolete file still exists: %s\n' "$file" >&2
    fail=1
  fi
done

for file in "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR/files/cleanup"; do
  if [[ -f "$file" ]]; then
    bash -n "$file"
  fi
done

if grep -RInE 'ansible|ansible-playbook|ansible-galaxy|homebrew_cask|homebrew:' \
  --exclude-dir=.git \
  --exclude-dir=docs \
  "$ROOT_DIR"; then
  printf 'obsolete Ansible references remain outside docs\n' >&2
  fail=1
fi

if command -v nix >/dev/null 2>&1; then
  nix --extra-experimental-features "nix-command flakes" flake check "$ROOT_DIR"
else
  printf 'skip: nix is not available, flake check not run\n'
fi

if [[ "${CHECK_BREW_STATE:-0}" == "1" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    printf 'brew is required when CHECK_BREW_STATE=1\n' >&2
    fail=1
  else
    brew bundle check --file "$ROOT_DIR/Brewfile.common"
    brew bundle check --file "$ROOT_DIR/Brewfile.home"
    brew bundle check --file "$ROOT_DIR/Brewfile.work"
  fi
fi

exit "$fail"
