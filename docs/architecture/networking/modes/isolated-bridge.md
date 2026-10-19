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

Container nodes with unused interfaces are also assigned an isolated bridge, created as a Linux
bridge. Each unused interface joins it through a Docker macvlan network in bridge mode, and is
renamed inside the container but left administratively down.
