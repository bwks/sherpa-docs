# Bridge

A `bridge` network, is implemented as a Libvirt
[Routed](https://wiki.libvirt.org/VirtualNetworking.html#routed-mode) mode network.

## Bridge interface

Create bridge interface to bridge lab-router / lab-vm's to the physical network.

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
