# Private Bridge

## Overview

A private bridge is implemented as an isolated layer 2 network.
Private bridge networks have no connectivity outside of the bridge.

All interfaces in the bridge are in the same layer 2 broadcast domain
and set to the up state.

![Bridge Network](network-private-bridge.svg)

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
  { name = "private", links = [ "dev01::gig2", "dev02::gig2", "dev03::eth1" ] },
]
```
