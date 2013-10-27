#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

vbox_version_file=/home/vagrant/.vbox_version

[ -f "$vbox_version_file" ] || exit 0

say install virtualbox guest additions

if [ -f /etc/init.d/virtualbox-ose-guest-utils ]; then
	/etc/init.d/virtualbox-ose-guest-utils stop ||:
fi

rmmod vboxguest
apt-get -y -f purge virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms virtualbox-ose-guest-utils

apt-get -y --no-install-recommends install \
	linux-headers-$(uname -r) dkms build-essential
apt-get -y --no-install-recommends install libdbus-1-3

mount -o loop VBoxGuestAdditions_$(cat "$vbox_version_file").iso /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -f VBoxLinuxAdditions.iso

/etc/init.d/vboxadd start

apt-get -y purge linux-headers-$(uname -r) build-essential
