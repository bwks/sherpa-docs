# Management

Each lab is assigned a management network with a unique IPv4 and IPv6 prefix.
Management networks are implemented as a Libvirt
[NAT](https://wiki.libvirt.org/VirtualNetworking.html#network-address-translation-nat)
network with some differences. Containers join the same bridge, `brm-<lab-id>`, through a Docker
bridge network.

Spanning tree is off on the management bridge, so a node's management interface forwards as
soon as it is attached, and nodes receive no STP BPDUs on it.

The allocated network acts as a NAT router and upstream DNS forwarder. The DHCP and DNS
functions for the lab are performed by a `lab-router` container instance.

![Management network: the brm bridge with source NAT to the host uplink, shared by a Docker bridge network for the lab router, Tailscale gateway and containers, and a libvirt NAT network for VMs and unikernels](network-mgmt.svg)

## Lab Router

Each lab management network has a dedicated `lab router`. The lab router runs the following
services.

### DHCP

A DHCP server with a range covering the lab node block, offsets 21 to 254. Each node has a
reservation for its own address in that range. See [IP addressing](../ip-addressing.md#addresses-in-a-range).

### DNS

A DNS service with the domain name `sherpa.lab.local`. Each node has a forward and reverse
DNS entry allocated in DNS. Nodes can be looked up via the hostname and FQDN.

### When the router stops

The lab router has no restart policy, and the Sherpa server does not start it when it starts.
After the server reboots it stays stopped, and the lab's nodes get no DHCP and resolve no names,
until the lab is resumed: `sherpa resume` starts the router before any node, or creates it
again if it is gone. `sherpa inspect` shows its state in the **Lab Router** table.


## Reaching Nodes

The management network is routed on the Sherpa server, so a client there reaches every node at
its management address. The lab's SSH config, `.sherpa/ssh/config`, connects to nodes there
directly. From any other machine, either join the lab's tailnet (below), or add `--ssh-jump` to
`sherpa ssh`, `sherpa up`, `sherpa provision` or `sherpa redeploy` to go through the Sherpa
server as an SSH jump host. See [SSH](../../ssh.md#reaching-nodes).

## Access through Tailscale

An optional `[tailscale]` manifest section creates a dedicated subnet router on
the lab's management network. It advertises that lab's IPv4 and optional IPv6
management prefixes to the owner's tailnet. The gateway uses address offset 3 in
each prefix, below the node allocation range.

Remote clients connect to the node management IPs shown by `sherpa inspect` after
the routes are approved and tailnet access policy allows them. The generated SSH
configuration reaches the nodes at those addresses directly, with no jump host.

See [Tailscale setup, lifecycle, and recovery](../tailscale.md).
