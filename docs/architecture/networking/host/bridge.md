# Bridge

A `bridge` network, is implemented as a Libvirt
[Routed](https://wiki.libvirt.org/VirtualNetworking.html#routed-mode) mode network.
Nodes are connected directly to the physical interface which provides connectivity
outside the host machine.

!!! Danger

    Be sure you understand the security posture of lab nodes and the implication of
    direct attached bridged networking before using this connectivity method.

## Bridge interface

Create bridge interface to bridge lab-router / lab nodes to the physical network.

```yaml
network:
  version: 2
  ethernets:
    enp9s0: {}
  bridges:
    br-sherpa0:
      interfaces: [enp9s0]
      parameters:
        stp: false
        forward-delay: 0
```
