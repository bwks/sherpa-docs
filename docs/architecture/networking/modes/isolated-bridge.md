# Isolated Bridge

## Virtual Machine

An `isolated` bridge is implemented as a libvirt
[Isolated](https://wiki.libvirt.org/VirtualNetworking.html#isolated-mode) network.
Isolated bridges have no connectivity outside of the bridge.

Each node with unused interfaces is assigned its own isolated bridge. Unused node interfaces are assigned to
an isolated bridge with the state set to down. Interfaces on the bridge are also isolated from
each other.

![A VM with eth0 on the management network and unused interfaces eth1 to ethN on its isolated bridge, with link state down](network-isolated.svg)

Dashed lines show interfaces with their link state set to down.

## Container

What a container's unused interfaces get depends on whether the container is on a link.

**On no link.** The node gets an isolated bridge, created as a Linux bridge. Each unused
interface joins it through its own Docker macvlan network in bridge mode, with the bridge as the
macvlan parent. The interface is named in the container and left administratively down. The
`juniper_evolved` container is the exception: its interface is left up, because it waits at boot
until every data interface is up. The server also sets the isolated bridge down, so the
interface has no carrier.

**On one or more links.** Every data interface of the container is a veth created into the
container's network namespace once the container has started. Docker only handles its
management network. Each link interface is a veth whose host end is attached to its peer by
an eBPF redirect. Each unused interface is also a veth, but it is not on the isolated bridge: it has no
Docker macvlan network and no eBPF redirect, and its host end joins no bridge. Both ends are
down, so the interface is down in the container and has no carrier. For `juniper_evolved`, the
container end is up and the host end is down.
