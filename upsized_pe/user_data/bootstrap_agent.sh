#!/bin/bash

exec > /root/user_data.log 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" whois vim-nox bash-completion ccze colordiff curl git htop lftp lynx mc mutt psmisc rsync sysstat telnet wget tree ack-grep make jq && \
curl -q https://gist.githubusercontent.com/fvoges/741de3b432e19c11c9bb/raw/874ea086b0f5e4bc07945dad3ea840f85a248a9a/rcinstall.sh|bash

PASSWORD=$(mkpasswd 'secret1!')
usermod --password $PASSWORD root

curl -k https://puppet.shadowsun.xyz:8140/packages/current/install.bash | \
  bash

puppet agent -tw2
puppet agent -t


