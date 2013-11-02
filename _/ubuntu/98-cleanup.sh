#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

say remove dhcp leases
rm -f /var/lib/dhcp/*

say remove udev rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules

say add some latency for dhclient
echo "pre-up sleep 2" >>/etc/network/interfaces

say package cleanup
apt-get -y autoremove
apt-get -y clean
