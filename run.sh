#!/bin/bash

set -e

if [ ! -f /usr/local/bin/brew ]; then
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if [ ! -f /usr/local/bin/ansible ]; then
	brew install ansible
fi

/usr/local/bin/ansible-playbook -i local playbook.yml -v -K
