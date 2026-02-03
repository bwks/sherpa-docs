# Bridge

## Overview

A bridge network is implemented as a libvirt
[Isolated](https://wiki.libvirt.org/VirtualNetworking.html#isolated-mode) network.
Bridged networks have no connectivity outside of the bridge.

All interfaces in the bridge are in the same layer 2 broadcast domain.
Interfaces attached to a bridged network are set to the up state.

## Diagram

![Bridge Network](network-bridge.svg)

## Example Manifest

Bridges are defined in the `manifest.toml`
file int the `bridges` section.

```toml
# manifest.toml
name = "betty-bridges"

nodes = [
  { name = "dev01", model = "cisco_cat8000v" },
  { name = "dev02", model = "cisco_cat8000v" },
  { name = "dev03", model = "arista_ceos" },
]

bridges = [
  [ "dev01::gig2", "dev02::gig2", "dev03::eth1" ],
]
```
