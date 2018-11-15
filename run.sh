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

if [ ! -f ~/.rvm/bin/rvm ]; then
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	\curl -sSL https://get.rvm.io | sed -E s/_rvm_print_headline/_rvm_version/ | bash -s stable --ruby --auto-dotfiles
fi

/usr/local/bin/ansible-galaxy install -r galaxy-roles.yml
/usr/local/bin/ansible-playbook -i local -e role=$1 playbook.yml -v -K

bash files/macos-settings.sh
