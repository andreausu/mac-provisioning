#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
	echo "You must provide a role: ./run.sh home|work"
	exit 1
fi

# Ask for the administrator password upfront
sudo -v

sudo mkdir -p /usr/local/bin
sudo chown andrea /usr/local/bin

# Keep-alive sudo until `clenaup.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ ! -f /usr/local/bin/brew ]; then
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
	eval "$(/usr/local/bin/brew shellenv)"
fi

if [ ! -f /usr/local/bin/ansible ]; then
	brew install ansible mas
fi

if [ ! -f ~/.zshrc ]; then
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ansible-galaxy install -r galaxy-roles.yml
ansible-playbook -i local -e role=$1 playbook.yml -v -K

# files/macos-settings.sh
