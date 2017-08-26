#!/bin/bash

set -e

if [ ! -f /usr/local/bin/brew ]; then
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if [ ! -f /usr/local/bin/ansible ]; then
	brew install ansible gpg
fi

if [ ! -f ~/.rvm/bin/rvm ]; then
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	\curl -sSL https://get.rvm.io | sed -E s/_rvm_print_headline/_rvm_version/ | bash -s stable --ruby --auto-dotfiles
fi

/usr/local/bin/ansible-playbook -i local playbook.yml -v -K
