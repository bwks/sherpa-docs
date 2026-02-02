# Isolated

An `isolated` network is implemented as a libvert
[Isolated](https://wiki.libvirt.org/VirtualNetworking.html#isolated-mode) network.
Isolated bridges, have no connectivity outside of the bridge.

Each node is assigned an isolated bridge. Unused node interfaces in a topology are assigned to
an isolated bridge with the state set to down.

![Alt text](network-isolated.svg "Isolated Network")
