#!/bin/bash

doctl compute tag create all
doctl compute tag create puppet
doctl compute tag create puppet-mom
doctl compute tag create puppet-compile

doctl compute firewall create \
  --name puppet-mom \
  --tag-names puppet-mom \
  --inbound-rules "protocol:tcp,ports:443,tag:vpn,address:213.86.212.121,address:81.174.144.48 protocol:tcp,ports:4433,tag:puppet protocol:tcp,ports:5432,tag:puppet protocol:tcp,ports:8081,tag:puppet protocol:tcp,ports:8140,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:8142,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:8143,tag:puppet protocol:tcp,ports:8170,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:61613,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:61616,tag:puppet"

doctl compute firewall create \
  --name puppet-compile \
  --tag-names puppet-compile \
  --inbound-rules "protocol:tcp,ports:8081,tag:puppet protocol:tcp,ports:8140,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:8142,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:61613,address:0.0.0.0/0,address:::/0"

doctl compute firewall create \
  --name all \
  --tag-names all \
  --inbound-rules "protocol:tcp,ports:22,tag:vpn,address:213.86.212.121,address:81.174.144.48"
  --outbound-rules "protocol:icmp,ports:0,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:0,address:0.0.0.0/0,address:::/0 protocol:udp,ports:0,address:0.0.0.0/0,address:::/0"

doctl compute droplet create pe.shadowsun.xyz \
  --size 's-2vcpu-4gb' \
  --tag-names all,puppet,puppet-mom \
  --user-data-file user_data/bootstrap_master.sh

doctl compute droplet create puppet01.shadowsun.xyz \
  --size 's-1vcpu-2gb' \
  --tag-names all,puppet,puppet-compile \
  --user-data-file user_data/bootstrap_compile.sh

doctl compute droplet create puppet02.shadowsun.xyz \
  --size 's-1vcpu-2gb' \
  --tag-names all,puppet,puppet-compile \
  --user-data-file user_data/bootstrap_compile.sh

doctl compute droplet create agent01.shadowsun.xyz \
  --size 's-1vcpu-1gb' \
  --tag-names all \
  --user-data-file user_data/bootstrap_agent.sh

doctl compute droplet create agent02.shadowsun.xyz \
  --size 's-1vcpu-1gb' \
  --tag-names all \
  --user-data-file user_data/bootstrap_agent.sh
