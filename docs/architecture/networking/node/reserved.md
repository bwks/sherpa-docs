# Reserved

A `reserved` network is implemented as a libvert
[Isolated](https://wiki.libvirt.org/VirtualNetworking.html#isolated-mode) network.
Isolated bridges, have no connectivity outside of the bridge.

Some nodes have interfaces that need to be assigned but cannot be used for data-plane traffic.
These interfaces are usually use for control plane processes within the Node itself.

If a node has reserved interfaces, it is assigned a reserved bridge.
Reserved interfaces are assigned to the bridge with the state set to up.

![Alt text](network-reserved.svg "Reserved Network")
