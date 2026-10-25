# IP Addressing

Every lab gets its own IPv4 and IPv6 address ranges. Sherpa allocates them automatically,
so labs never overlap with each other on the same server.

## Management Network

Each lab has a [management network](modes/management.md) with both an IPv4 and an IPv6 range.
Every node receives one address from each.

| | IPv4 | IPv6 |
| - | ---- | ---- |
| Server range | `172.31.0.0/16` | `fd00:b00b::/48` |
| Range per lab | `/24` | `/64` |
| Config setting | `management_prefix_ipv4` | `management_prefix_ipv6` |

The first range in the server range is skipped, so the first lab gets `172.31.1.0/24`.
Each new lab takes the next free range. Ranges are returned when a lab is destroyed.

A range is free only if no lab holds it and it does not overlap a network already on one
of the server's interfaces, such as another service's network or a bridge left behind by
a lab that was not cleaned up. The database accepts each range for only one lab, so labs
started at the same time never receive the same range.

The IPv6 ranges are private (ULA) addresses. They are routed only inside the lab and its NAT
router, not on the internet.

### Addresses in a range

Each range is split into three blocks. The same offsets apply to IPv4 and IPv6. In the IPv4
range `172.31.1.0/24`:

| Offsets | Block | Used by |
| ------- | ----- | ------- |
| `.1`–`.10` | Sherpa infrastructure | `.1` gateway, `.2` lab router (DHCP and DNS), `.3` [Tailscale](tailscale.md) gateway when enabled. The rest are reserved. |
| `.11`–`.20` | Lab control planes | `.11`–`.12` shared addresses for [Talos Kubernetes clusters](../../nodes/linux/talos-linux.md#control-plane-endpoint) with three controllers. The rest are reserved. |
| `.21`–`.254` | Lab nodes | Node management addresses and the DHCP range |

Nodes are numbered in the order they appear in the manifest. The first node gets offset 21
(`172.31.1.21`), the second 22, and so on, so a lab can have up to 234 nodes. For IPv6 the offset
is added to the `/64`, so the first node in `fd00:b00b:0:1::/64` gets `fd00:b00b:0:1::15`.

Use `sherpa inspect <lab-id>` to see the addresses assigned to each node.

!!! note
    Node IP addresses are assigned based on their position in the manifest. Reordering the list
    changes addresses on the next `sherpa up`.
    Management addresses can't be set in the manifest. A manifest node with `ipv4_address` or
    `ipv6_address` is rejected as an unknown field.

## Loopback Addresses

Each lab also has a loopback range, used for node console access and
[point-to-point links](modes/point-to-point.md).

| | IPv4 | IPv6 |
| - | ---- | ---- |
| Server range | `127.127.0.0/16` | `fd00:1001::/48` |
| Range per lab | `/24` | `/64` |

Each node gets an IPv4 loopback address matching its position in the manifest, so the first node
is `.1`. The loopback ranges cannot be changed.

## Changing the Ranges

Set the ranges in the server configuration file and restart `sherpad`:

```toml
management_prefix_ipv4 = "172.31.0.0/16"
management_prefix_ipv6 = "fd00:b00b::/48"
```

Leave `management_prefix_ipv6` unset to use `fd00:b00b::/48`. See the
[server configuration](../../configuration/sherpa.md) for all settings.

Choose ranges that do not overlap your physical network, VPNs, or other Sherpa servers. This
matters most if you connect labs to a tailnet, because routes from different servers must be
distinct. Changing a range affects new labs only. Existing labs keep their addresses.

## Server Addresses

The server listens on IPv4 and, optionally, IPv6.

| Setting | Description |
| ------- | ----------- |
| `server_ipv4` | IPv4 address to listen on. Defaults to `127.0.0.1`. |
| `server_ipv6` | IPv6 address to listen on. When set, the server listens on IPv4 and IPv6 at once. |

You can override both at start up with the `SHERPA_SERVER_IPV4` and `SHERPA_SERVER_IPV6`
environment variables. The server's TLS certificate automatically includes the configured
addresses. The client configuration has matching connection settings for choosing which address
to connect to.

## IPv6 Support

Every node receives an IPv6 management address alongside its IPv4 address. Whether the node
configures that address itself depends on its model.

These models do not yet configure an IPv6 management address:

- OpenBSD. cloud-init's OpenBSD network renderer never configures IPv6 addresses, and it fails
  on an IPv6 default route, which would leave the node with no network. Sherpa therefore sends
  OpenBSD nodes IPv4 settings only. See [OpenBSD](../../nodes/bsd/open-bsd.md#notes).
- Palo Alto PAN-OS
- SONiC Linux

The generated [SSH config](../ssh.md) always uses the IPv4 address as the host name.
