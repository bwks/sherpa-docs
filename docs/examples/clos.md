# CLOS

![Two SONiC spine VMs, each linked to all four SONiC leaf VMs](clos.svg)

A two-tier leaf-spine (CLOS) fabric of six SONiC VMs. Every leaf connects to every spine, and
there are no spine-to-spine or leaf-to-leaf links, so any two leaves are always two hops apart
and routing can spread traffic across both spines (ECMP).

| Tier  | Nodes                                  | Model                                    |
| ----- | -------------------------------------- | ---------------------------------------- |
| Spine | `spine01`, `spine02`                   | [SONiC](../nodes/sonic/sonic-linux.md)   |
| Leaf  | `leaf01`, `leaf02`, `leaf03`, `leaf04` | [SONiC](../nodes/sonic/sonic-linux.md)   |

The interfaces follow a fixed pattern, which makes the cabling easy to read and to extend:

- On a spine, `ethN` connects to leaf `N`: `eth1` to `leaf01`, `eth4` to `leaf04`.
- On a leaf, `eth31` connects to `spine01` and `eth32` to `spine02`.

| Link | Spine     | Spine interface | Leaf     | Leaf interface |
| ---- | --------- | --------------- | -------- | -------------- |
| 1    | `spine01` | `eth1`          | `leaf01` | `eth31`        |
| 2    | `spine01` | `eth2`          | `leaf02` | `eth31`        |
| 3    | `spine01` | `eth3`          | `leaf03` | `eth31`        |
| 4    | `spine01` | `eth4`          | `leaf04` | `eth31`        |
| 5    | `spine02` | `eth1`          | `leaf01` | `eth32`        |
| 6    | `spine02` | `eth2`          | `leaf02` | `eth32`        |
| 7    | `spine02` | `eth3`          | `leaf03` | `eth32`        |
| 8    | `spine02` | `eth4`          | `leaf04` | `eth32`        |

To add a leaf, add the node and connect its `eth31` and `eth32` to the next free interface on
each spine, for example `eth5` for `leaf05`.

## Manifest

```toml
name = "sherpa-clos"

[[nodes]]
name = "spine01"
model = "sonic_linux"

[[nodes]]
name = "spine02"
model = "sonic_linux"

[[nodes]]
name = "leaf01"
model = "sonic_linux"

[[nodes]]
name = "leaf02"
model = "sonic_linux"

[[nodes]]
name = "leaf03"
model = "sonic_linux"

[[nodes]]
name = "leaf04"
model = "sonic_linux"

[[links]]
src = "spine01::eth1"
dst = "leaf01::eth31"

[[links]]
src = "spine01::eth2"
dst = "leaf02::eth31"

[[links]]
src = "spine01::eth3"
dst = "leaf03::eth31"

[[links]]
src = "spine01::eth4"
dst = "leaf04::eth31"

[[links]]
src = "spine02::eth1"
dst = "leaf01::eth32"

[[links]]
src = "spine02::eth2"
dst = "leaf02::eth32"

[[links]]
src = "spine02::eth3"
dst = "leaf03::eth32"

[[links]]
src = "spine02::eth4"
dst = "leaf04::eth32"
```
