# Sandboxes

The `arista_eos` container (cEOS), `nokia_srlinux` and the `sonic_linux` container each run in a
[Flatcar Container Linux](https://www.flatcar.org/) virtual machine of their own, a sandbox.
Inside it, Docker runs the node's image privileged, so the network OS has the VM's network
interfaces as its own. Its privileges reach that VM's kernel, not the server's. Every other
container model runs on the server's Docker, see [Container](container.md).

A sandbox is a [virtual machine](virtual-machine.md) to Sherpa for `down`, `resume` and
`status`:

| Operation | What happens |
| --------- | ------------ |
| `sherpa down` | The VM is shut down over ACPI, which stops the container cleanly |
| `sherpa resume` | The VM boots, and the container restarts with what it saved |
| `sherpa redeploy` | The VM and its disks are removed and made again from the generated config |
| `sherpa destroy` | The VM and its disks are removed |

A sandbox stopped before its first boot finished needs a `sherpa redeploy`.

A lab brought up before these models ran in sandboxes runs them as containers on the server's
Docker. `sherpa down` and `sherpa resume` refuse such a node:

```
Node 'ceos1' was made before its model ran in a sandbox and has none; destroy the lab and bring it up again
```

Destroy the lab and bring it up again.

## Access

| Command | Result |
| ------- | ------ |
| `sherpa ssh <node>` | SSH to the node's management address |
| `sherpa console <node>` | The network OS CLI on the VM's serial console |
| `sherpa vnc <node>` | Refused: `<node> runs in a sandbox, which has a serial console only. Use 'sherpa console <node>' instead.` |

Press Enter to open the CLI. It waits for the container to run. When you exit the CLI, the
prompt comes back. See [Serial Console](console.md).

The container is not on the server's Docker, so `docker exec` on the server does not reach it.

## Resources

The VM gets the node's `memory` plus 1024 MiB, and its `cpu.count` vCPUs. Both come from the
manifest, or from the image when the manifest leaves them out. The server counts them when it
decides whether a lab fits. Inside the VM the container has no limits.

## Volumes

The node's volumes, the generated config, startup files, certificates and secret files, are
copied onto the VM's config drive when the node is created.

- A change to a volume's source on the server is not seen until `sherpa redeploy`.
- A writable volume is copied into the container. What the network OS writes stays in the VM
  across `sherpa down` and `sherpa resume`. `sherpa redeploy` starts again from the generated
  config.
- Secret files sit on the config drive in the server's storage pool until `sherpa destroy` or
  `sherpa redeploy`.
- A writable volume's empty folders are made in the container too.

The config drive is an ISO 9660 image, so a volume of a node in a sandbox may hold only files
and folders. `sherpa up` and `sherpa redeploy` refuse a volume whose source holds any of these,
before any VM is made, naming the path:

| Refused | Why |
| ------- | --- |
| A symlink | Sandboxes do not follow it; copy what it points to instead |
| A FIFO, socket or device | Only files and folders go on the drive |
| A folder more than four levels below the volume's source | ISO 9660 allows eight levels, and the drive takes four above a volume |
| A file of 4 GiB or more | ISO 9660 holds files under 4 GiB |
| A name longer than 31 characters | ISO 9660's names are that long at most |

```
Node 'ceos1' runs in a sandbox, whose config drive cannot carry volume source /srv/ceos1/flash/link: it is a symlink, which is not followed
```

## Networking

Each data interface on a [point-to-point link](networking/modes/point-to-point.md) or a
[private bridge](networking/modes/private-bridge.md) is a NIC of the VM, and the VM's management
NIC is on the lab's [management network](networking/modes/management.md) with the node's
management addresses.

### The Sandbox's Own Address

The VM has a second NIC on the lab's management network, which the network OS does not see:
the VM keeps it in a network namespace of its own. It has addresses of its own, IPv4, and IPv6
when the lab has IPv6:

- They come after the nodes' addresses in the lab's management network: in a lab of N nodes the
  first sandbox, in manifest order, has the address node N + 1 would have, the second N + 2, and
  so on.
- The lab's name server names them `<node>-sbx` and `<node>-sbx.sherpa.lab.local`, and its DHCP
  server keeps the IPv4 address for the sandbox, also while the node is down.
- They are its only addresses besides its IPv6 link-local one: it takes none from a router
  advertisement. The network OS's interfaces are not affected.
- They stay the same across `sherpa down`, `sherpa resume` and `sherpa redeploy`, and are given
  back by `sherpa destroy`.
- Nothing listens on them; they answer ping from the server and from the lab's nodes.

Because each sandbox takes an address, a lab with sandboxes has room for fewer than 234 nodes.
`sherpa up` refuses a lab whose nodes and sandboxes need more:

```
Manifest - 118 nodes defined, 117 of them in a sandbox with a management address of its own,
which need 235 addresses, but a lab has 234
```

A node may not be named `<node>-sbx` after a node that runs in a sandbox.

## Readiness

A node is ready once SSH answers on its management address. Two cases are ready once their VM
reports that the container started:

- a cEOS node without the config Sherpa generates: `ztp.method = "disabled"`, or a config of its
  own;
- an SR Linux node with a config of its own.

`ready_check.port` overrides both. A VM that reports a failure, for example that the container
cannot be started, fails the node with that reason.

## Base Image

Sandboxes boot the default version of the [`flatcar_sandbox`](../nodes/linux/flatcar-sandbox.md)
image, Flatcar's OpenStack image, which you import as any VM image. It is the base image of
sandboxes only: a node of model `flatcar_sandbox` is refused; use
[`flatcar_linux`](../nodes/linux/flatcar-linux.md) for a Flatcar VM.

`sherpa up` and `sherpa redeploy` refuse a lab with a sandbox, before they create anything, when
the server has no `flatcar_sandbox` image:

```
The arista_eos container, nokia_srlinux and the sonic_linux container run in a sandbox, which
boots the flatcar_sandbox image, and the server has none. ...
```

The VM boots an overlay of the image through Flatcar's own bootloader, with the kernel arguments
in the image: Sherpa adds none and never changes the image. While it boots, `sherpa console`
shows the bootloader's menu and the kernel's boot messages, then the network OS CLI. Once the
VM's root file system is up, the kernel prints only errors there, so its info messages, such as
interface renames, never mix into the CLI. An image with the
[optional `quiet` edit](../nodes/linux/flatcar-sandbox.md#optional-boot-quietly) prints only
errors from the kernel's start on, and boots faster.

## Docker Stores

A VM does not hold a copy of its image for each node. Each container image version has a Docker
store, a disk with the image loaded once, and every sandbox of the version boots on it without
copying the image.

- The first `sherpa up` or `sherpa redeploy` that needs a version makes its store. It takes
  minutes, and a progress message says so. A later operation that needs the same store waits for
  it.
- A store belongs to no lab. `sherpa destroy` keeps it.
- Importing or pulling the version again, or deleting it, removes its store; the next
  `sherpa up` makes a new one. Both are refused while a lab's sandbox disk is built on the store,
  running or stopped: destroy the lab first.
- `sherpad` removes what an interrupted store build left when it starts. Finished stores are
  kept.

A store is `virtiob.qcow2` in its version's folder of the model's `sandbox` folder in the
[images directory](storage.md#images), such as
`/opt/sherpa/images/arista_eos/sandbox/4.35.0F/virtiob.qcow2` for cEOS 4.35.0F. No image can
have the version `sandbox`.
