# Basic

![dev01, a Cisco IOSv VM, linked from gig0/1 to eth-1/1 on dev02, a Nokia SR Linux container](basic.svg)

The smallest useful lab: two network devices joined by a single point-to-point link.

| Node    | Model                                            | Kind            |
| ------- | ------------------------------------------------ | --------------- |
| `dev01` | [Cisco IOSv](../nodes/cisco/cisco-iosv.md)       | Virtual machine |
| `dev02` | [Nokia SR Linux](../nodes/nokia/nokia-srlinux.md) | Container       |

| Link | `dev01` interface | `dev02` interface |
| ---- | ----------------- | ----------------- |
| 1    | `gig0/1`          | `eth-1/1`         |

The link joins a VM to a container. A link can connect any mix of VMs and containers, so
multi-vendor labs can combine both kinds of node. See
[Point-to-Point](../architecture/networking/modes/point-to-point.md) for how links are built.

Both nodes are also on the lab's management network on their management interfaces, which
the diagram leaves out.

```toml
name = "sherpa-basic"

[[nodes]]
name = "dev01"
model = "cisco_iosv"

[[nodes]]
name = "dev02"
model = "nokia_srlinux"

[[links]]
src = "dev01::gig0/1"
dst = "dev02::eth-1/1"
```
