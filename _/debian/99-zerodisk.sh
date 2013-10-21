#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

say minimize disk
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
sync
sync
