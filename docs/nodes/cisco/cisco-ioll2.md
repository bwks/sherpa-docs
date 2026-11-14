# Cisco IOL L2

Cisco IOL L2 is IOL XE L2, the switch build of IOS on Linux, as the `cisco_ioll2` model. It is a
container based image. The router build is [Cisco IOL](cisco-iol.md).

## Base Image

`cisco_ioll2` is built from your own Cisco Modeling Labs (CML) images with
[docker-cisco-iol](https://github.com/bwks/docker-cisco-iol), the same way as `cisco_iol`. Build
it from the `ioll2-xe-<version>.tar.gz` tarball, as shown in
[Cisco IOL: Base Image](cisco-iol.md#base-image). The built image is
`localrepo/cisco_ioll2:<version>`, for example `localrepo/cisco_ioll2:17.18.02`.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| Tested Version       | 17.18.02  |
| CPU                  | 1         |
| RAM                  | 768 MiB   |
| ZTP                  | `volume`  |
| Management Interface | Ethernet0/0 |
| Data Interfaces      | Ethernet0/1-Ethernet3/3 (15) |
| MTU                  | 1500      |
| Privileged           | No        |

The interfaces are the same as on `cisco_iol`: Ethernet ports in slots of four, `Ethernet0/0` to
`Ethernet3/3`. `Ethernet0/0` is management, so the data interfaces are `Ethernet0/1` to
`Ethernet3/3`. With `interfaces.data_count` set lower, IOL still shows whole slots of four.

`memory` is IOL's own memory; the container's limit is `memory` plus 128 MiB for the launcher.

## Startup Configuration

The startup configuration is the one `cisco_iol` gets (hostname, the `sherpa` login and yours,
SSH, and the management address with a default route through the management network), with two
differences for a switch:

- `Ethernet0/0` is a routed port, `no switchport`, so it can hold the management address.
- `ip routing` is on, so the default route through the management network works.

The data interfaces are left as IOL starts them: switchports, with no VLAN configuration.

## Example Manifest

Two routers on one VLAN through an access port each, and a trunk to a second switch.

```toml
name = "cisco-ioll2"

[[nodes]]
name = "sw1"
model = "cisco_ioll2"
version = "17.18.02"

[[nodes]]
name = "sw2"
model = "cisco_ioll2"
version = "17.18.02"

[[nodes]]
name = "r1"
model = "cisco_iol"
version = "17.18.02"

[[nodes]]
name = "r2"
model = "cisco_iol"
version = "17.18.02"

[[links]]
src = "sw1::Ethernet0/1"
dst = "r1::Ethernet0/1"

[[links]]
src = "sw2::Ethernet0/1"
dst = "r2::Ethernet0/1"

[[links]]
src = "sw1::Ethernet0/2"
dst = "sw2::Ethernet0/2"
```

## Switching

Configure VLANs, access and trunk ports and SVIs on the switch as on any IOS switch. For the lab
above, on `sw1` (on `sw2` the SVI takes `10.0.10.3`):

```
vlan 10
 name users
!
interface Ethernet0/1
 switchport mode access
 switchport access vlan 10
 no shutdown
!
interface Ethernet0/2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10
 no shutdown
!
interface Vlan10
 ip address 10.0.10.1 255.255.255.0
 no shutdown
```

Give `r1` and `r2` addresses in `10.0.10.0/24` on `Ethernet0/1`, and they reach each other and
the SVIs through the switches.

!!! note

    The management port and the SVIs share the global routing table, as there is no management
    VRF, and `ip routing` is on. The switch routes between its SVIs and the management network,
    and its default route points to the management network.

## Node Access

=== "SSH"

    ```
    sherpa ssh sw1
    ```

=== "Console"

    The IOL console is the container's terminal. Detach with `Ctrl-P` `Ctrl-Q`.

    ```
    docker attach sw1-<lab-id>
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`. Sherpa reports the node ready once the
  container is running; SSH answers about a minute later, once IOL has booted.
- The other IOL notes, on saving the configuration with `write memory`, MTU 1500, checksum
  offload, link state, IOL application IDs and ZTP off, apply to `cisco_ioll2` as well. See
  [Cisco IOL: Notes](cisco-iol.md#notes).
