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

The data interfaces are left as IOL starts them: switchports in `dynamic auto` mode, up, and
access ports in VLAN 1 until a trunk is negotiated. Unlike the routers' interfaces, they are not
shut down.

```
sw1#show interfaces Ethernet0/2 switchport
Name: Et0/2
Switchport: Enabled
Administrative Mode: dynamic auto
Operational Mode: static access
Administrative Trunking Encapsulation: negotiate
...
Access Mode VLAN: 1 (default)
```

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

!!! warning

    Trunks need an image built with docker-cisco-iol that includes
    [the VLAN tag fix](https://github.com/bwks/docker-cisco-iol/pull/2). An image built before it
    hands IOL every frame on a trunk untagged, so VLANs do not cross the trunk and each switch
    sees itself as the spanning-tree root. Rebuild the image to fix it.

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

The routers' `Ethernet0/1` starts shut down, so bring it up with an address in `10.0.10.0/24`.
On `r1` (on `r2` it takes `10.0.10.12`):

```
interface Ethernet0/1
 ip address 10.0.10.11 255.255.255.0
 no shutdown
```

The routers then reach each other and both SVIs through the switches, VLAN 10 crossing the
trunk tagged. Both switches agree on one root bridge for VLAN 10:

```
sw2#show spanning-tree vlan 10
VLAN0010
  Spanning tree enabled protocol rstp
  Root ID    Priority    32778
             Address     aabb.cc00.0100
             Cost        100
             Port        3 (Ethernet0/2)
...
Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Et0/1               Desg FWD 100       128.2    P2p
Et0/2               Root FWD 100       128.3    P2p

sw1#show interfaces trunk
Port           Mode             Encapsulation  Status        Native vlan
Et0/2          on               802.1q         trunking      1

sw1#show mac address-table dynamic vlan 10
Vlan    Mac Address       Type        Ports
----    -----------       --------    -----
  10    aabb.cc00.0220    DYNAMIC     Et0/2
  10    aabb.cc00.0310    DYNAMIC     Et0/1
  10    aabb.cc00.0410    DYNAMIC     Et0/2
  10    aabb.cc80.0200    DYNAMIC     Et0/2
```

`aabb.cc00.0310` is `r1` on the access port, and `aabb.cc00.0410` is `r2`, learnt across the
trunk. The other two are `sw2`'s own addresses.

!!! note

    The management port and the SVIs share the global routing table, as there is no management
    VRF, and `ip routing` is on. The switch routes between its SVIs and the management network,
    and its default route points to the management network.

### Saving VLANs

The switch is a VTP server, so VLANs are not in the running configuration. IOL keeps them in its
VLAN database, `vlan.dat`, which Sherpa keeps in the lab folder with NVRAM. Changes to VLANs are
written to it at once, without `write memory`.

| Event | VLANs (`vlan.dat`) | Port and SVI configuration |
| ----- | ------------------ | -------------------------- |
| Cold boot (`sherpa down`, container stopped, `sherpa resume`) | Kept, saved or not | Kept only after `write memory` |
| `sherpa redeploy` | Cleared | Cleared, back to the startup configuration |

Save the ports and SVIs with `write memory` as on `cisco_iol`. A switch that saved nothing comes
back from a cold boot with its VLANs but with its ports in `dynamic auto` and no SVI addresses.

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
- Link state works as on `cisco_iol`: an interface goes down about 12 seconds after its link
  loses carrier, and an interface with no link shows `notconnect`. See
  [Cisco IOL: Link State](cisco-iol.md#link-state).
- The other IOL notes, on saving the configuration with `write memory`, MTU 1500, checksum
  offload, IOL application IDs and ZTP off, apply to `cisco_ioll2` as well. See
  [Cisco IOL: Notes](cisco-iol.md#notes). VLANs are saved apart from the configuration; see
  [Saving VLANs](#saving-vlans).
