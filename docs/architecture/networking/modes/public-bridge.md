# Public Bridge

!!! Note

    Attaching nodes to a public bridge is a planned feature. The host bridge setup below is
    available now.

A `public bridge` is implemented as a layer 2 network bridged to a physical interface.
A node connected to a public bridge has its virtual interface directly bridged to a physical
interface on the host machine. IP address configuration is shared with the network of the
physical uplink interface.

!!! Danger

    Be sure you understand the security posture of lab nodes and the implication of
    directly attaching to the physical network before using this connectivity method.

![Containers, a VM and a unikernel attached to a public bridge that is bridged to the host's physical NIC](network-public-bridge.svg)

## Host Bridge

The host bridge joins a physical interface on the Sherpa server to a Linux bridge, so that lab
nodes can be connected directly to the physical network.

![Host bridge networking: the physical NIC is a member of the br-sherpa0 Linux bridge, and the sherpa-bridge libvirt network sits on top of it](network-public-bridge-host.svg)

- **Physical NIC** is a member of the bridge and has no IP address of its own.
- **`br-sherpa0`** is a Linux bridge that you create on the host, for example with netplan. Create
  it before running `sherpad init`.
- **`sherpa-bridge`** is a libvirt network in bridge mode on top of `br-sherpa0`. `sherpad init`
  creates it.

### Example Configuration

This netplan configuration adds the physical interface `enp9s0` to `br-sherpa0`. Replace `enp9s0`
with the host's physical interface.

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
