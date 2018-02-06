#!/bin/bash

exec > /root/user_data.log 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" whois vim-nox bash-completion ccze colordiff curl git htop lftp lynx mc mutt psmisc rsync sysstat telnet wget tree ack-grep make jq && \
curl -q https://gist.githubusercontent.com/fvoges/741de3b432e19c11c9bb/raw/874ea086b0f5e4bc07945dad3ea840f85a248a9a/rcinstall.sh|bash

PASSWORD=$(mkpasswd 'secret1!')
usermod --password $PASSWORD root

mkdir -p /etc/puppetlabs/facter/facts.d
cat > /etc/puppetlabs/facter/facts.d/facts.txt <<EOF
my_environment=production
my_application=puppet
my_role=compile
EOF

mkdir -p /etc/puppetlabs/puppet
cat > /etc/puppetlabs/puppet/csr_attributes.yaml <<YAML
extension_requests:
  pp_environment: production
  pp_application: puppet
  pp_role: compile
YAML

curl -k https://pe.shadowsun.xyz:8140/packages/current/install.bash | \
  bash -s \
  main:dns_alt_names=$(hostname -s),$(hostname -f),mom,mom.$(hostname -d),master,master.$(hostname -d),puppet,puppet.$(hostname -d) \
  extension_requests:pp_environment=production extension_requests:pp_application=puppet extension_requests:pp_role=compile \
  --puppet-service-ensure false

puppet agent -tw2 --noop
puppet agent -t
puppet resource service puppet ensure=running



