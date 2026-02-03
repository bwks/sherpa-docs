# Public

A `public` network, is implemented as a Libvirt
[Routed](https://wiki.libvirt.org/VirtualNetworking.html#routed-mode) mode network.
A node connected to a physical network has its interface directly bridged to a physical interface
on the host machine.

!!! Danger

    Be sure you understand the security posture of lab nodes and the implication of
    direct attached public networking before using this connectivity method.
