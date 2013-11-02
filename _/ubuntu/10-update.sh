#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

say install core packages
apt-get -y --no-install-recommends install sudo ssh ca-certificates lsb-release vim-tiny

say update base system
apt-get update
apt-get -y upgrade
