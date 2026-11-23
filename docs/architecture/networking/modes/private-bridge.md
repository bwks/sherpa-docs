# Private Bridge

## Overview

A private bridge is implemented as an isolated layer 2 network.
Private bridge networks have no connectivity outside of the bridge.

All interfaces in the bridge are in the same layer 2 broadcast domain
and set to the up state.

A VM joins the bridge through its tap. A container joins it through a veth pair, made
into the container once it has started, whose host end is a port of the bridge; the
container's other data interfaces are veths too. A bridge of containers alone works,
and a container restarted outside Sherpa gets its bridge interface back from the
server's [scanner](../../../configuration/sherpa.md#scanner) within one scan.

Labs made by an earlier release joined a container on no link to a bridge through a Docker
macvlan network. Redeploy the node, or destroy and rebuild the lab, to move it to veths.

![Private bridge: two VMs and a container connected to the same isolated bridge](network-private-bridge.svg)

## Example Manifest

Bridges are defined in the `manifest.toml`
file in the `bridges` section.

```toml
# manifest.toml
name = "betty-bridges"

[[nodes]]
name = "dev01"
model = "cisco_cat8000"

[[nodes]]
name = "dev02"
model = "cisco_cat8000"

[[nodes]]
name = "dev03"
model = "arista_eos"
kind = "container"

[[bridges]]
name = "private"
links = ["dev01::gig2", "dev02::gig2", "dev03::eth1"]
```
