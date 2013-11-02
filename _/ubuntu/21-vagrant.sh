#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

id -u vagrant >/dev/null 2>&1 || exit 0

say setup vagrant

echo 'UseDNS no' >>/etc/ssh/sshd_config

echo 'vagrant ALL=NOPASSWD:ALL' >/etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

echo 'Vagrant sanal makinesine hoşgeldiniz.' >/var/run/motd

mkdir -p /home/vagrant/.ssh
wget --no-check-certificate \
	'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' \
	-O /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys

apt-get -y --no-install-recommends install nfs-common

date >/etc/vagrant_box_build_time
