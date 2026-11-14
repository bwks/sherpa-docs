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

Cisco IOL's interfaces are fixed at MTU 1500. A Linux node linked to an IOL node must set MTU
1500 on that interface, or TCP across the link stalls; see [Cisco IOL](../../../nodes/cisco/cisco-iol.md).

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

#### When a Node Restarts

A VM or unikernel that boots again, a container started again, and a redeployed node get new
link ends, and Sherpa attaches their links again in both directions, impairments included.
A container's interfaces are made again in its new network namespace first. A link whose peer
is down waits for it, and is attached when the peer starts. `sherpa resume` and
`sherpa redeploy` list each link that is not attached; see
[`sherpa resume`](../../../command-reference.md#sherpa-resume).

A node started outside Sherpa gets new link ends too: a virtual machine started with
`virsh start` after `virsh destroy` or a shutdown, and a container started with `docker start`
or restarted with `docker restart` or a restart policy, which also takes all of the
container's data interfaces with it. The server's [scanner](../../../configuration/sherpa.md#scanner)
finds these links and attaches them again, making the container's interfaces again first, so
they come back within `scanner.interval_secs` (30 seconds by default). It checks only nodes
that are running: a node you stopped or paused is left alone, and its links wait for it. A
reboot from inside the guest, `virsh reboot`, and a pause and unpause keep the same link ends,
so nothing needs attaching. [`sherpa inspect`](../../../command-reference.md#link-states)
shows each link's state.

#### When a Neighbour Stops

A link behaves like a cable: when the node at one end stops, the interface at the other end
loses its link, and the network operating system there sees the interface go down, as it
would if the cable were pulled, so routing protocols react to the interface going down rather
than waiting for their hold timers. When the node starts again and its link is attached, the interface comes back up.

| What happens to the peer | What the surviving node sees |
| ------------------------ | ---------------------------- |
| stopped, shut down, crashed or removed (`docker stop`, `virsh destroy`, a guest power-off) | its interface loses carrier (`NO-CARRIER` on Linux) |
| paused (`docker pause`, `virsh suspend`, or `sherpa down`, which pauses containers) | its interface loses carrier, until the peer is unpaused |
| started or unpaused again | its interface has carrier again, once the link is attached |
| the link cannot be attached (`failed` in `sherpa inspect`) | both ends lose carrier |

On a container, the interface inside the container shows no carrier. On a virtual machine or
unikernel, the guest's virtual network card reports its link down, as `virsh domif-setlink`
would set it; a guest that ignores the link state of its network card does not see it. The
change is made to the running virtual machine only: one that is started again starts with its
links up, and Sherpa takes a link down again if its peer is still down.

When Sherpa changes a link's state depends on what stopped or started the peer:

- `sherpa resume`, of one node or the whole lab, changes it before the command returns, for
  every node it starts or unpauses. A node started while its peer is still paused has its link
  taken down at once.
- `sherpa redeploy` replaces the node within the command, and its peers keep their carrier
  throughout: frames sent to it while it is replaced are dropped.
- `sherpa down`, a pause, and changes made outside Sherpa are seen by the
  [scanner](../../../configuration/sherpa.md#scanner), within `scanner.interval_secs` (30
  seconds by default) of the change. With the scanner disabled, they do not change the link,
  and only `sherpa resume` and `sherpa redeploy` do.

The network operating system may take longer to act on the change: Cisco IOL, for example,
takes an interface down about 12 seconds after its link loses carrier; see
[Cisco IOL](../../../nodes/cisco/cisco-iol.md#link-state).

Sherpa changes a link only when its state changes. To simulate a link failure, take the host
end down yourself, for example `ip link set tpb3-ab12cd34 down` on the Sherpa server, or the
interface of a virtual machine with `virsh domif-setlink`; it stays down while both nodes keep
running. Sherpa brings it back up when the link's state next changes, for example when one of
the nodes stops and starts, and once when the Sherpa server restarts, as it then checks every
link afresh.

A restarted container's interfaces have new MAC addresses, so its peer reaches it once the
peer's neighbour entry is refreshed, which Linux does within seconds; other network operating
systems may take longer.

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
