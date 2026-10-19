# Public Bridge

!!! Note

    This is a planned feature.

A `public bridge` is implemented as a layer 2 network bridged to a physical interface.
A node connected to a public bridge has its virtual interface directly bridged to a physical
interface on the host machine. IP address configuration is shared with the network of the
physical uplink interface.

!!! Danger

    Be sure you understand the security posture of lab nodes and the implication of
    directly attaching to the physical network before using this connectivity method.

![Containers, a VM and a unikernel attached to a public bridge that is bridged to the host's physical NIC](network-public-bridge.svg)
