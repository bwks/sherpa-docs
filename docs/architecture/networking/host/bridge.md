# Bridge

A host `bridge` joins a physical interface on the Sherpa server to a Linux bridge, so that lab
nodes can be connected directly to the physical network.

![Host bridge networking: the physical NIC is a member of the br-sherpa0 Linux bridge, and the sherpa-bridge libvirt network sits on top of it](bridge.svg)

- **Physical NIC** is a member of the bridge and has no IP address of its own.
- **`br-sherpa0`** is a Linux bridge that you create on the host, for example with netplan. Create
  it before running `sherpad init`.
- **`sherpa-bridge`** is a libvirt network in bridge mode on top of `br-sherpa0`. `sherpad init`
  creates it.

!!! note

    Attaching node interfaces to `sherpa-bridge` is a planned feature. See
    [Public Bridge](../node/public-bridge.md).

## Example Configuration

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
