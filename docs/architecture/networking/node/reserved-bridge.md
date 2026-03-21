# Reserved Bridge

A `reserved` bridge is implemented as a libvirt
[Isolated](https://wiki.libvirt.org/VirtualNetworking.html#isolated-mode) network.
Isolated bridges, have no connectivity outside of the bridge.

Some nodes have interfaces that need to be assigned but cannot be used for data-plane traffic.
These interfaces are usually for control plane processes within the node itself.

If a node has reserved interfaces, it is assigned a reserved bridge.
Reserved interfaces are assigned to the bridge with the state set to up.

Reserved bridges are currently only provisioned for Virtual Machine nodes.

![Alt text](network-reserved.svg "Reserved Network")
