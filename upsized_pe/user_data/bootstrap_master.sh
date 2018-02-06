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
my_role=mom
EOF

mkdir -p /etc/puppetlabs/puppet
cat > /etc/puppetlabs/puppet/csr_attributes.yaml <<YAML
extension_requests:
  pp_environment: production
  pp_application: puppet
  pp_role: mom
YAML

cat > /tmp/pe.conf <<HOCON
{
  # Stock all-in-one answers for 2016.2.x and newer
  "pe_install::puppet_master_dnsaltnames": [ "$(hostname -s)", "mom", "mom.$(hostname -d)", "master", "master.$(hostname -d)", "puppet", "master.$(hostname -d)", "puppet.$(hostname -d)"  ]
  "console_admin_password": "puppetlabs"
  "puppet_enterprise::puppet_master_host": "%{::trusted.certname}"

  # Additional customization
  "puppet_enterprise::profile::master::check_for_updates": false
  "puppet_enterprise::send_analytics_data": false
  "puppet_enterprise::profile::database::puppetdb_hosts": ["puppet01.shadowsun.xyz","puppet02.shadowsun.xyz"]

}
HOCON

mkdir -p /etc/puppetlabs/code/environments/production/data
cat > /etc/puppetlabs/code/environments/production/data/common.yaml <<YAML
---

#this class doesn't take params for puppetdb_host and puppetdb_port which sucks
#we could probably interpolate the server and port from above but this is just
#a prototype
#Since pe_install::puppetdb_certname is a single entry and there's no way to
#override the puppetdb_port in pe_install we get mismatching arrays passed here
puppet_enterprise::profile::controller::puppetdb_urls:
 - 'https://pe.shadowsun.xyz:8081'


#Drop puppetdb Java Heap Size
#PE3.2 and above
pe_puppetdb::pe::java_args:
  -Xmx: '256m'
  -Xms: '64m'
#PE3.1 and below
pe_puppetdb::java_args:
  -Xmx: '256m'
  -Xms: '64m'
#Drop the activemq java heap size
pe_mcollective::role::master::activemq_heap_mb: '96'
#Allow access to the puppetdb performance dashboard from non-localhost
#This is insecure and also allows access to all API endpoints without verification
pe_puppetdb::pe::listen_address: '0.0.0.0'

#PE3.7
#Allow access to the puppetdb performance dashboard from non-localhost
#This is insecure and also allows access to all API endpoints without verification
puppet_enterprise::profile::puppetdb::listen_address: '0.0.0.0'
puppet_enterprise::profile::amq::broker::heap_mb: '96'
puppet_enterprise::profile::master::java_args:
  Xmx: '192m'
  Xms: '128m'
  'XX:MaxPermSize': '=96m'
  'XX:PermSize': '=64m'
  'XX:+UseG1GC': ''
puppet_enterprise::profile::puppetdb::java_args:
  Xmx: '128m'
  Xms: '128m'
  'XX:MaxPermSize': '=96m'
  'XX:PermSize': '=64m'
  'XX:+UseG1GC': ''
puppet_enterprise::profile::console::java_args:
  Xmx: '64m'
  Xms: '64m'
  'XX:MaxPermSize': '=96m'
  'XX:PermSize': '=64m'
  'XX:+UseG1GC': ''
puppet_enterprise::master::puppetserver::jruby_max_active_instances: 1  #PE3.7.2 only
puppet_enterprise::profile::console::delayed_job_workers: 1
#shared_buffers takes affect during install but is not managed after
puppet_enterprise::profile::database::shared_buffers: '4MB'
#puppet_enterprise::profile::console::classifier_synchronization_period: 0
#2015.3.2 and above
puppet_enterprise::profile::orchestrator::java_args:
  Xmx: '64m'
  Xms: '64m'
  'XX:+UseG1GC': ''
YAML

cat > /root/compileplus.pp <<PUPPET
pe_node_group { 'PE Infrastructure':
  ensure             => 'present',
  classes            => {
    'puppet_enterprise' => {
      'certificate_authority_host'   => 'pe.shadowsun.xyz',
      'console_host'                 => 'pe.shadowsun.xyz',
      'database_host'                => 'pe.shadowsun.xyz',
      'mcollective_middleware_hosts' => ['pe.shadowsun.xyz'],
      'pcp_broker_host'              => 'pe.shadowsun.xyz',
      'puppetdb_host'                => 'pe.shadowsun.xyz',
      'puppet_master_host'           => 'puppet.shadowsun.xyz',
      'send_analytics_data'          => false
    }
  },
  environment        => 'production',
  environment_trumps => false,
  parent             => 'All Nodes',
}

pe_node_group { 'PE Master':
  ensure             => 'present',
  classes            => {
    'pe_repo'                                          => {},
    'pe_repo::platform::ubuntu_1604_amd64'             => {},
    'puppet_enterprise::profile::master'               => {
      'check_for_updates' => false
    },
    'puppet_enterprise::profile::master::mcollective'  => {},
    'puppet_enterprise::profile::mcollective::peadmin' => {}
  },
  environment        => 'production',
  environment_trumps => false,
  parent             => 'All Nodes',
  pinned             => ['pe.shadowsun.xyz'],
  rule               => ['or',
  ['and',
    ['=',
      ['trusted', 'extensions', 'pp_role'],
      'compile']
    ],
    ['=', 'name', 'pe.shadowsun.xyz']
  ],
}
pe_node_group { 'PE Master - Compile Master':
  ensure             => 'present',
  classes            => {
    'puppet_enterprise::profile::master' => {
      'puppetdb_host' => '${trusted["certname"]}'
    }
  },
  environment        => 'production',
  environment_trumps => false,
  parent             => 'All Nodes',
  rule               => ['and',
  ['=',
    ['trusted', 'extensions', 'pp_role'],
    'compile']
  ],
}
pe_node_group { 'PE PuppetDB':
  ensure             => 'present',
  classes            => {
    'puppet_enterprise::profile::puppetdb' => { }
  },
  environment        => 'production',
  environment_trumps => false,
  parent             => 'All Nodes',
  pinned             => ['pe.shadowsun.xyz'],
  rule               => ['or',
  ['and',
    ['=',
      ['trusted', 'extensions', 'pp_role'],
      'compile']
    ],
    ['=', 'name', 'pe.shadowsun.xyz']
  ],
}
pe_node_group { 'PE PuppetDB - Compile Master':
  ensure             => 'present',
  classes            => {
    'puppet_enterprise::profile::puppetdb' => {
      'gc_interval' => 0
    }
  },
  environment        => 'production',
  environment_trumps => false,
  parent             => 'All Nodes',
  rule               => ['and',
  ['=',
    ['trusted', 'extensions', 'pp_role'],
    'compile']
  ],
}
PUPPET


curl -Lo /tmp/pe.tgz 'https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=ubuntu&rel=16.04&arch=amd64&ver=latest'

tar -C /tmp -xzf /tmp/pe.tgz
cd /tmp/puppet-enterprise*
./puppet-enterprise-installer -y -c /tmp/pe.conf


