#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "You must provide a role: ./run.sh home|work"
fi

# Ask for the administrator password upfront
sudo -v

# Keep-alive sudo until `clenaup.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ ! -f /usr/local/bin/brew ]; then
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if [ ! -f /usr/local/bin/ansible ]; then
	brew install ansible gpg mas
fi

if [ ! -f ~/.zshrc ]; then
	curl -L http://install.ohmyz.sh | sh
fi

/usr/local/bin/ansible-galaxy install -r galaxy-roles.yml
/usr/local/bin/ansible-playbook -i local -e role=$1 playbook.yml -v -K

bash files/macos-settings.sh
