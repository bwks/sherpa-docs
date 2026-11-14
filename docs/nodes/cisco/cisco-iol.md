# Cisco IOL

Cisco IOL (IOS on Linux) is a container based image. The `cisco_iol` model is IOL XE, a router.
The IOL XE L2 switch is the `cisco_ioll2` model, on its own page:
[Cisco IOL L2](cisco-ioll2.md).

Sherpa runs IOL from your own Cisco Modeling Labs (CML) IOL images, rebuilt for Sherpa with
[docker-cisco-iol](https://github.com/bwks/docker-cisco-iol). Neither Sherpa nor
docker-cisco-iol includes any Cisco files.

## Base Image

See the [general notes](general.md) for how to obtain the CML images, and Cisco's warning about
using them outside CML.

The image is built the same way for both IOL models, so this section covers `cisco_ioll2` as well.
You need the IOL image tarballs from a CML release's reference platform files:

- `iol-xe-<version>.tar.gz` for `cisco_iol`
- `ioll2-xe-<version>.tar.gz` for `cisco_ioll2`

The `iol-xe-serial-4eth` image definition uses the same `iol-xe` tarball; Sherpa has no serial
interface model.

### Build the image

On the Sherpa server, clone docker-cisco-iol and give its build script each CML tarball:

```
git clone https://github.com/bwks/docker-cisco-iol.git
cd docker-cisco-iol
./build-iol-image.sh /path/to/iol-xe-17-18-02.tar.gz
./build-iol-image.sh /path/to/ioll2-xe-17-18-02.tar.gz
```

The script loads the CML image into Docker and builds a Sherpa image on top of it. The model and
version come from the CML image's tag:

| CML image | Sherpa image |
| --------- | ------------ |
| `iol-xe/iol-xe:17-18-02` | `localrepo/cisco_iol:17.18.02` |
| `iol-xe/ioll2-xe:17-18-02` | `localrepo/cisco_ioll2:17.18.02` |

The build keeps Cisco's own IOL launcher from the CML image, so no licence file is needed. It
adds a small program that connects the container's interfaces to IOL.

### Import image

Register the images built on the Sherpa server by scanning the local container images:

```
sherpa server image scan --container
```

Built on another machine, save the image and import the archive:

```
docker save localrepo/cisco_iol:17.18.02 -o cisco_iol-17.18.02.tar
sherpa server image import --src cisco_iol-17.18.02.tar --model cisco_iol --version 17.18.02
```

!!! warning

    The images must have the repo `localrepo/cisco_iol` or `localrepo/cisco_ioll2`. The scan
    only registers images with those repos as the `cisco_iol` and `cisco_ioll2` models. The
    first version registered becomes the default.

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

IOL has Ethernet ports in slots of four: `Ethernet0/0` to `Ethernet0/3`, then `Ethernet1/0`, up
to `Ethernet3/3`. `Ethernet0/0` is management, so the data interfaces are `Ethernet0/1` to
`Ethernet3/3`. With `interfaces.data_count` set lower, IOL still shows whole slots of four.

`memory` is IOL's own memory, the size of the whole IOL process. The container's memory limit is
`memory` plus 128 MiB for the launcher. `cpu.count` limits the container's CPU; IOL uses one CPU.

## Example Manifest

```toml
name = "cisco-iol"

[[nodes]]
name = "r1"
model = "cisco_iol"
version = "17.18.02"

[[nodes]]
name = "r2"
model = "cisco_iol"
version = "17.18.02"

[[links]]
src = "r1::Ethernet0/1"
dst = "r2::Ethernet0/1"
```

## VLAN Subinterfaces

!!! warning

    802.1Q tagged frames need an image built with docker-cisco-iol that includes
    [the VLAN tag fix](https://github.com/bwks/docker-cisco-iol/pull/2). An image built before it
    hands IOL every received frame untagged, so subinterfaces receive nothing. Rebuild the image
    to fix it.

IOL routes between VLANs on `encapsulation dot1Q` subinterfaces. The parent interface starts
shut down, so bring it up with no address, and put the addresses on the subinterfaces.

### Router on a stick

`r1` trunked to a [`cisco_ioll2`](cisco-ioll2.md) switch, with a host in VLAN 10 on `sw1`'s
`Ethernet0/2` and a host in VLAN 20 on `Ethernet0/3`:

```toml
[[links]]
src = "r1::Ethernet0/1"
dst = "sw1::Ethernet0/1"
```

On `sw1`:

```
vlan 10
vlan 20
!
interface Ethernet0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20
 no shutdown
!
interface Ethernet0/2
 switchport mode access
 switchport access vlan 10
 no shutdown
!
interface Ethernet0/3
 switchport mode access
 switchport access vlan 20
 no shutdown
```

On `r1`:

```
interface Ethernet0/1
 no ip address
 no shutdown
!
interface Ethernet0/1.10
 encapsulation dot1Q 10
 ip address 10.60.10.1 255.255.255.0
!
interface Ethernet0/1.20
 encapsulation dot1Q 20
 ip address 10.60.20.1 255.255.255.0
```

```
r1#show ip interface brief | include Ethernet0/1
Ethernet0/1            unassigned      YES unset  up                    up
Ethernet0/1.10         10.60.10.1      YES manual up                    up
Ethernet0/1.20         10.60.20.1      YES manual up                    up
```

The hosts, with `r1` as their gateway, then reach each other through `r1`, one hop away
(`ttl=63`). On `r1`'s side of the trunk, a ping from the VLAN 10 host to the VLAN 20 host arrives
tagged 10 and leaves tagged 20, and the reply comes back the other way.

### Between routers

Subinterfaces also work on a link between two routers, with no switch. Give both ends a
subinterface with the same VLAN:

```
interface Ethernet0/1
 no shutdown
!
interface Ethernet0/1.30
 encapsulation dot1Q 30
 ip address 10.60.30.2 255.255.255.0
```

Ping and SSH work across it. A tagged frame carries a full 1500-byte IP packet, so
`ping <address> size 1500 df-bit` succeeds across the subinterface as it does on an untagged
interface.

## Node Access

=== "SSH"

    ```
    sherpa ssh r1
    ```

=== "Console"

    The IOL console is the container's terminal. Detach with `Ctrl-P` `Ctrl-Q`.

    ```
    docker attach r1-<lab-id>
    ```

## Notes

Except for the startup configuration, these notes apply to [`cisco_ioll2`](cisco-ioll2.md) as well.

- Approximate time for the system to be ready: `1 minute`. Sherpa reports the node ready once the
  container is running; SSH answers about a minute later, once IOL has booted and generated its
  RSA key.
- The startup configuration sets the hostname, the `sherpa` login and yours, SSH, and the
  management address on `Ethernet0/0`, with a default route through the management network. The
  data interfaces are left as IOL starts them: shut down, with no address.
- `write memory` saves to IOL's NVRAM, which Sherpa keeps in the lab folder. A saved
  configuration wins over the startup configuration and survives `sherpa down` and
  `sherpa resume`, and a restart of the container, such as after the server restarts.
  `sherpa redeploy` clears it and starts the node again from the startup configuration.
- IOS closes an SSH session that runs a single command before a long command such as `ping`
  ends. Run those in an interactive session (`sherpa ssh r1`).
- **MTU 1500.** IOL's interfaces are fixed at MTU 1500 and cannot be changed. Sherpa's link ends
  are MTU 9600, so a Linux node linked to an IOL node must set MTU 1500 on that interface.
  Otherwise it advertises a larger TCP MSS than IOL can take, and TCP across the link stalls,
  although ping works.
- Sherpa turns transmit checksum offload off on the server's side of every IOL interface, as IOL
  cannot finish a checksum that the server left for "hardware" to fill in. Without it, TCP to
  IOL fails while ping works. This is done for links, disabled interfaces and the management
  interface. An IOL node in a private bridge with no link takes its bridge interfaces as Docker
  macvlan interfaces, which have no server side to change; give it a link as well if TCP to IOL
  through the bridge fails.
- IOL does not see link state: an interface stays up when its link goes down.
- Each IOL node in a lab gets its own IOL application ID, from which IOL derives its MAC
  addresses. A lab can hold at most 999 nodes before an IOL node; a later IOL node is refused.
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node is the image as
  shipped: IOL boots with no configuration, runs its own autoinstall, and has no management
  address and no `sherpa` login, so `sherpa ssh` cannot reach it. Reach it on its console with
  `docker attach <node-name>-<lab-id>`. Its NVRAM is still kept, and the node's `volumes` from the
  manifest are mounted.
