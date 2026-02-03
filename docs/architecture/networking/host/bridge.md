# Bridge

A `bridge` interface allows nodes to be connected directly to the physical network.

TODO: Add diagram

## Example Configuration

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
