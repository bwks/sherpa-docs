# Isolated Bridge

## Virtual Machine

An `isolated` bridge is implemented as a libvirt
[Isolated](https://wiki.libvirt.org/VirtualNetworking.html#isolated-mode) network.
Isolated bridges, have no connectivity outside of the bridge.

Each node is assigned an isolated bridge. Unused node interfaces in a topology are assigned to
an isolated bridge with the state set to down. Interfaces on the bridge are also isolated from
each other.

![Isolated Network](network-isolated.svg)

## Container
