#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

[ -f .vbox_version ] || exit 0

say install virtualbox guest additions

if [ -f /etc/init.d/virtualbox-ose-guest-utils ]; then
	/etc/init.d/virtualbox-ose-guest-utils stop ||:
fi

rmmod vboxguest
apt-get -y -f purge virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms virtualbox-ose-guest-utils

apt-get -y --no-install-recommends install \
	linux-headers-$(uname -r) dkms build-essential
apt-get -y --no-install-recommends install libdbus-1-3

mount -o loop VBoxGuestAdditions.iso /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -f VBoxLinuxAdditions.iso

/etc/init.d/vboxadd start

apt-get -y purge linux-headers-$(uname -r) dkms build-essential
