# Point-to-Point

Point to Point links allow for arbitrary connections between
lab nodes. This enables to simulation of small to large network
topologies resembling real-life implementations.

Links between nodes are defined in the `manifest.toml` file in the `links` section.

There are multiple methods to link nodes together. The method used
depends on the lab requirements.

## P2P Bridge

P2P Bridges are the default P2P link type. They allow for
connectivity between VM's and Containers and also allow
for packet captures on the interfaces via Wireshark or TCPDump.

Node interfaces in a link are assigned to a dedicated linux bridge.
The bridges are connected via a veth pair virtual wire.

![Alt text](network-p2p-bridge.svg "Point-to-Point Bridge Link")

### Configuration

PTP Bridge is the default configuration and does not required any mode
setting to be defined.

```toml
nodes = [
    { name = "dev01", model = "arista_veos" },
    { name = "dev02", model = "arista_ceos", version = "4.35.1F" },
]
links = [
    { src = "dev01::eth1", dst = "dev02::eth1" },
]
```

!!! Note

    `p2p-bridge` is the only supported link type between
    containers and virtual machines.

## P2P UDP

P2P UDP allow for the transmission of any protocol between Virtual Machine nodes only.
A point-to-point virtual wire is created directly between the network interfaces using
UDP tunneling.

![Alt text](network-p2p-udp.svg "Point-to-Point UDP Link")

### Caveats

PTP UDP link interfaces CANNOT be used as for packet captures.

### Configuration

PTP UDP is configured on a per-link basis with the `mode = "p2p-udp"` setting.

```toml
nodes = [
    { name = "dev03", model = "arista_veos" },
    { name = "dev04", model = "arista_veos" },
]
links = [
    { src = "dev03::eth1", dst = "dev04::eth1", mode = "p2p-udp" },
]
```

!!! Note

    `p2p-udp` is only supported between virtual machines nodes.

## P2P vEth

P2P vEth allow for the transmission of any protocol between container nodes.
A point-to-point virtual wire is created directly between the network interfaces with a vEth pair.

P2P vEth interfaces CAN be used for packet captures.

![Alt text](network-p2p-veth.svg "Point-to-Point vEth Link")

### Caveats

PTP vEth links are created outside the docker process and are not automatically re-attached
to a container if the container crashes.

### Configuration

PTP vEth is configured on a per-link basis with the `mode = "p2p-veth"` setting.

```toml
nodes = [
    { name = "dev05", model = "arista_ceos", version = "4.35.1F" },
    { name = "dev06", model = "arista_ceos", version = "4.35.1F" },
]
links = [
    { src = "dev05::eth1", dst = "dev06::eth1", mode = "p2p-veth" },
]
```

!!! Note

    `p2p-veth` is only supported between container nodes.
