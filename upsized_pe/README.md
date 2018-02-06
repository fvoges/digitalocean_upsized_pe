

Shell script to bring up an upsized PE environment on DigitalOcean using Ubuntu 16.04 LTS.

**WARNING:** this creates VMs with root password stored in this repo. Ubuntu has password SSH disabled by default and this repo is supposed to be use for quick tests/demos. If you wat to leave the servers created with this files running for more than a couple of hours, secure them properly (at least  restrict SSH access using DOs firewall and set a proper root password)


It requires DigitalOcean's `doctl` CLI tool.

Defaults for doctl below. this is the config form tugboat, not doctl. but the values are the same for both.


```yaml
defaults:
  region: lon1
  image: ubuntu-16-04-x64
  size: s-1vcpu-1gb
  ssh_key: [24268, 24269, 690427, 722799, 743589, 2473096, 9966886,]
  private_networking: 'true'
  backups_enabled: 'true'
  ip6: 'true'
```

Used but not included is the load balancer for puppet.shadowsun.xyz (for Puppet and Orchestrator) and a floating IP for the MOM (pe.shadowsun.xyz)




