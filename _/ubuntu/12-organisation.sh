#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

say add organisation package repository
wget -qO /etc/apt/sources.list.d/19.list deb.ondokuz.biz/19.list
wget -qO- deb.ondokuz.biz/archive.key | apt-key add -
apt-get update

if id -u vagrant >/dev/null 2>&1; then
	say setup vagrant home directory
	sudo -u vagrant sh <<-EOF
		cd ~
		git init
		git remote add origin https://github.com/19/vagrant.git
		git clean -fdx
		git pull origin master
	EOF
fi

if id -u admin >/dev/null 2>&1 && [ -d /tmp/admin/.git ]; then
	say setup admin home directory
	adduser admin sudo
	sudo -u admin sh <<-EOF
		cd ~
		git init
		git clean -fdx
		git pull /tmp/admin
		git remote add origin https://github.com/19/admin.git
	EOF
	if [ -d /tmp/sbin/.git ]; then
		sudo -u admin sh <<-EOF
			mkdir ~/sbin
			cd ~/sbin
			git init
			git pull /tmp/sbin
			git remote add origin https://github.com/19/sbin.git
		EOF
	fi
fi

say apply ssh policy
cat >>/etc/ssh/sshd_config <<CONF
	PermitUserEnvironment yes
	PermitRootLogin no
	PasswordAuthentication no
	ChallengeResponseAuthentication no
CONF
service ssh restart
