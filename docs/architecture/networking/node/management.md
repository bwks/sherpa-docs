# Management

Each lab is assigned a management network with a unique IPv4 and IPv6 prefix.
Management networks are implemented as a Libvirt
[NAT](https://wiki.libvirt.org/VirtualNetworking.html#network-address-translation-nat)
network with some differences.

The allocated network acts as a NAT router and upstream DNS forwarder. The DHCP and DNS
functions for the lab are performed by a `lab-router` container instance.

![Alt text](network-mgmt.svg "Management Network")

## Lab Router

Each lab management network has a dedicated `lab router`. The lab router runs the following
services.

### DHCP

A DHCP server with a range of addresses starting from the `first address +10`
and ending at the `last address -1`.

### DNS

A DNS service with the domain name `sherpa.lab.local`. Each node has a forward and reverse
DNS entry allocated in DNS. Nodes can be looked up via the hostname and FQDN.


## Access through Tailscale

An optional `[tailscale]` manifest section creates a dedicated subnet router on
the lab's management network. It advertises that lab's IPv4 and optional IPv6
management prefixes to the owner's tailnet. The gateway uses address offset 3 in
each prefix, below the node allocation range.

Remote clients connect to the node management IPs shown by `sherpa inspect` after
the routes are approved and tailnet access policy allows them. Generated SSH
configurations continue to use the configured Sherpa jump host.

See [Tailscale setup, lifecycle, and recovery](../tailscale.md).
