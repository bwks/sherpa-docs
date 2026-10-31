# Point-to-Point

Point to Point links allow for arbitrary connections between
lab nodes. This enables to simulation of small to large network
topologies resembling real-life implementations.

Links between nodes are defined in the `manifest.toml` file in the `links` section. Every link
is a P2P eBPF link.

## P2P eBPF

P2P eBPF links provide high-performance, zero-copy packet forwarding between
nodes using an eBPF TC classifier program. An eBPF redirect program is attached
to each end of the link, forwarding ingress packets directly to the peer
interface's egress in kernel space — bypassing the Linux bridge and network stack
entirely.

P2P eBPF links support both virtual machines and containers, including
mixed VM-to-container links.

Every link end is MTU 9600 on the host. A VM is told this MTU, so a virtio interface in the
guest comes up at 9600 unless the guest's own configuration sets another.

![Point-to-point eBPF link: a VM and a container connected through tap-a and tap-b, with an eBPF redirect forwarding packets between them in the kernel](network-p2p-ebpf.svg)

Every L2 protocol passes end to end, including LLDP, STP, LACP, CDP, pause frames, and VLAN
and QinQ tagged frames, and each link end on the host can be captured with `tcpdump`.

### Configuration

A link needs only its two ends.

```toml
[[nodes]]
name = "dev01"
model = "arista_veos"

[[nodes]]
name = "dev02"
model = "arista_ceos"

[[links]]
src = "dev01::eth1"
dst = "dev02::eth1"
```

#### Link Impairments

P2P eBPF links support optional link impairments via TC netem, which
coexists with the eBPF redirect program. Each direction has its own netem, on the host end
its traffic leaves through. The manifest sets both directions the same; the
[`sherpa link impair`](../../../command-reference.md#sherpa-link-impair) command sets each one
on a running lab.

```toml
[[links]]
src = "dev01::eth1"
dst = "dev02::eth1"

[links.impairment]
delay = 10
jitter = 2
loss_percent = 0.5
```

Available impairment parameters:

| Parameter         | Description                        | Unit         |
| ----------------- | ---------------------------------- | ------------ |
| `delay`           | One-way delay                      | milliseconds |
| `jitter`          | Delay jitter                       | milliseconds |
| `loss_percent`    | Packet loss percentage             | 0.0 - 100.0  |
| `reorder_percent` | Packet reordering percentage       | 0.0 - 100.0  |
| `corrupt_percent` | Bit-flip corruption percentage     | 0.0 - 100.0  |

### The removed `p2p` setting

Links once had a `p2p` setting, and a link without `p2p = true` was joined through a pair of
Linux bridges. Since Sherpa 0.4.14 every link is a P2P eBPF link, and a manifest that still
sets `p2p` (to `true` or `false`) fails validation: delete the setting from the link.

A lab created before 0.4.14 with links that did not set `p2p = true` has bridge links, which
Sherpa no longer supports. Destroy such a lab before upgrading, and create it again after.
