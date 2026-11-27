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

## Access

| Command | Result |
| ------- | ------ |
| `sherpa ssh <node>` | SSH to the node's management address |
| `ssh <node>-sbx.<lab-id>` | SSH to the sandbox itself, as `core`, see [SSH Into the Sandbox](#ssh-into-the-sandbox) |
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
- The lab's name server names them `<node>-sbx` and `<node>-sbx.sherpa.lab.local`.
- They stay the same across `sherpa down`, `sherpa resume` and `sherpa redeploy`, and are given
  back by `sherpa destroy`.
- They answer ping from the server and from the lab's nodes, and SSH, see
  [SSH Into the Sandbox](#ssh-into-the-sandbox).

Because each sandbox takes an address, a lab with sandboxes has room for fewer than 234 nodes.
`sherpa up` refuses a lab whose nodes and sandboxes need more:

```
Manifest - 118 nodes defined, 117 of them in a sandbox with a management address of its own,
which need 235 addresses, but a lab has 234
```

A node may not be named `<node>-sbx` after a node that runs in a sandbox.

### SSH Into the Sandbox

To debug a sandbox, log in to the VM itself on its own address:

```
ssh core@<node>-sbx
```

- `<node>-sbx` resolves on the lab's name server, so this works from the lab's nodes. From your
  machine, the lab's [SSH config](ssh.md#sandboxes) has a host `<node>-sbx.<lab-id>` for each
  sandbox: `ssh <node>-sbx.<lab-id>`. Its addresses, IPv4 and IPv6, work too.
- The login is `core`, with your own [SSH keys](ssh-keys.md) only: no password, and no `root`.
  `core` can run `docker ps`, `docker logs`, `journalctl` and `sudo`.
- `ssh <node>` and `sherpa ssh <node>` still reach the network OS, on the node's address.
  `sherpa ssh` does not reach the sandbox.
- The network OS sees neither the sandbox's SSH server nor its address.
- The sandbox keeps its SSH host key across `sherpa down` and `sherpa resume`, and has a new one
  after `sherpa redeploy`. The lab's SSH config does not check it.

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

The VM boots the image through Flatcar's own bootloader. While it boots, `sherpa console`
shows Flatcar's boot messages before the network OS CLI.

## Docker Stores

A VM does not hold a copy of its image for each node. Each image has a Docker store, a disk with
the image loaded once, and every sandbox of the image boots on it without copying the image.

- The first `sherpa up` or `sherpa redeploy` that needs an image makes its store. It takes
  minutes, and a progress message says so. A later operation that needs the same store waits for
  it.
- A store belongs to no lab. `sherpa destroy` keeps it.
- Nothing removes a store when its image is deleted or imported again; an image imported again
  gets a store of its own.
- `sherpad` removes what an interrupted store build left when it starts. Finished stores are
  kept.

The stores are in the [storage pool](storage.md).
