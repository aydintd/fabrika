#!/bin/bash

say() { echo -e >&2 "\033[36;01m${*}\033[0m"; }

packages="
bash-completion
bzip2
bzr
curl
file
git
iselect
less
libssl-dev
lsb-release
mc
mercurial
moreutils
pdmenu
rsync
ruby
ruby-dev
ruby-highline
ssh
subversion
sudo
tmux
unzip
vim
"

say install base packages
apt-get -y update
apt-get -y -m --no-install-recommends install $packages
