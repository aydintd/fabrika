#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

say setup grub
cat >/etc/default/grub <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2>/dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX="debian-installer=en_US.UTF-8"
EOF
update-grub
