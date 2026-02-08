# Public Bridge

A `public bridge` is implemented as network layer 2 network bridged to a physical interface.
A node connected to a public bridge has its virtual interface directly bridged to a physical
interface on the host machine. IP address configuration is shared with the network of the
physical uplink interface.

!!! Danger

    Be sure you understand the security posture of lab nodes and the implication of
    directly attaching to the phyical networking before using this connectivity method.

![Bridge Network](network-public-bridge.svg)
