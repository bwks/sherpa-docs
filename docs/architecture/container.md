# Container

Containers are supported via the [Docker](https://docs.docker.com/) engine runtime. Sherpa communicates with Docker through the [Bollard](https://github.com/fussybeaver/bollard) async API library — all operations are native API calls, not shell-outs to the Docker CLI.

![Container architecture: sherpad drives the Docker Engine, which runs each container through containerd on the shared host kernel; each part of the container is backed by a host resource](container.svg)

## How it Works

When a lab is created, Sherpa performs the following for each container node:

1. **Generate** ZTP configuration files and volumes for the node's model
2. **Create** the container with environment variables, volume mounts, and network settings
3. **Attach** the management network as the primary interface
4. **Start** the container
5. **Connect** additional data plane networks sequentially
6. **Rename** interfaces to match the model's naming convention (e.g. `eth1` to `e1-1`)

## Resource Allocation

Every container model has a default data interface count and privileged mode. A container node's
`memory` and `cpu.count` from the manifest are applied as Docker limits when the container is
created:

- **`memory`** is a hard memory limit, converted from MB to bytes, with the swap limit set equal
  to it so the container cannot swap.
- **`cpu.count`** is a CPU quota (Docker `NanoCpus`, `cpu.count` billionths of a CPU each). It
  limits the CPU time the container may use, on any of the server's CPUs; it does not pin the
  container to CPUs.

A limit the manifest leaves out is not set, so Docker leaves it unlimited. The image's CPU and
memory values are not applied to containers. Two models size their limits differently: a
`juniper_evolved` container takes `memory` (or the image's) as the memory of the router VM inside
it, and its container's memory limit is that plus 2048 MB, with no CPU quota; a Cisco IOL
container's memory limit is `memory` (or the image's) plus 128 MB.

Options configurable in the manifest, in the node's [`container`](../manifest.md#container-object)
group unless noted:

- **`container.privileged`** — run the container in privileged mode (admins only)
- **`container.shm_size`** — shared memory size in bytes
- **`container.user`** — override the container user
- **`container.commands`** — override the default command
- **`interfaces.data_count`** — the number of data interfaces
- **`environment_variables`** — key-value pairs passed to the container

## Image Management

Container images can be sourced in two ways:

- **Pull from registry** — `sherpa server image pull <image>:<tag>` downloads from any OCI-compliant registry (Docker Hub, GHCR, etc.) and optionally exports to a `.tar.gz` archive in the containers directory.
- **Load from archive** — import a `.tar` or `.tar.gz` archive into the local Docker daemon via the Docker CLI or Sherpa's image import.

## Networking

Container networking uses two Docker network drivers:

### Management Network

A Docker **bridge** network provides management connectivity. All containers are attached to this network on their first interface (`eth0`) with an assigned IPv4 and IPv6 address. This network provides SSH access and ZTP communication with the server.

The network is named after the lab. If a Docker network of that name is already there, for example one an earlier lab of the same name left, `sherpa up` uses it only when its subnets, gateways and bridge are the ones the lab was given. Otherwise the up is refused before it creates anything, with an error that names the network and what differs, and the network is left as it is: remove it with `docker network rm <name>` once nothing uses it, then run `sherpa up` again.

### Data Networks

Each end of a [link](networking/modes/point-to-point.md) on a container is a veth pair. Once the container has started, Sherpa creates the veth with its container end already inside the container's network namespace, named, in promiscuous mode and up. The host end is joined to its peer by an [eBPF redirect program](networking/modes/point-to-point.md#p2p-ebpf). Nothing runs inside the container, so links work with any image, including images without the `ip` command or without a shell.

A [private bridge](networking/modes/private-bridge.md) member is a veth pair made the same way, whose host end is a port of the private bridge.

A container on a link or a private bridge gets veth pairs for all its data interfaces, and a disabled interface stays down with no carrier. A container on no link and no private bridge uses Docker **macvlan** networks in bridge mode for its unconnected interfaces, on the node's isolated bridge.

After attachment, data interfaces are set to promiscuous mode and brought up. Disabled interfaces (unconnected links) are left admin-down, except on a `juniper_evolved` container: it waits at boot until all its data interfaces are up, so its disabled interfaces stay up, on the node's isolated bridge or with no carrier.

## Provisioning

Containers do not use traditional ZTP methods (TFTP, cloud-init). Instead, provisioning is handled through a combination of volume mounts, environment variables, and commands. The specific method varies by model — typically configuration files mounted as volumes, environment variables, or a combination of both.

### File Injection

Files reach a container through:

- **`container.volumes`** — bind mounts of server paths (admins only)
- **[`container` provisioners](provisioners/container.md)** — secret files, mounted at `/run/secrets`

Containers take no `text_files`, `startup_scripts` or `systemd_units`; a manifest that sets one
on a container is refused.

Every container gets the [lab CA and its node certificate](certificates.md), mounted read-only
at `/etc/sherpa/certs/`.

## Console Access

Container access is available through:

- **SSH** — connect via `sherpa ssh <node>` to nodes that run an SSH server
- **Docker exec** — attach to the container shell via `docker exec -it <container> <shell>`

## Lifecycle

| Operation | Description |
| --------- | ----------- |
| Create | Container is created and started with network attachments |
| Down | `sherpa down` pauses a running container (Docker pause); it is not stopped. A container that is already paused or stopped is reported as such |
| Resume | `sherpa resume` unpauses a paused container, or starts a stopped one; a running container is left alone |
| Redeploy | Container is killed and removed, then recreated with fresh configuration |
| Destroy | Container is killed (SIGKILL), removed, and associated Docker networks are cleaned up |
