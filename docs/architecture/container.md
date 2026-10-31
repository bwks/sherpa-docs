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

Every container model has default resource parameters for CPU, RAM, data interface count, and privileged mode. These can be overridden in the manifest.

Additional options configurable in the manifest:

- **`privileged`** — run the container in privileged mode
- **`shm_size`** — shared memory size in bytes
- **`user`** — override the container user
- **`environment_variables`** — key-value pairs passed to the container
- **`commands`** — override the default entrypoint/command

## Image Management

Container images can be sourced in two ways:

- **Pull from registry** — `sherpa server image pull <image>:<tag>` downloads from any OCI-compliant registry (Docker Hub, GHCR, etc.) and optionally exports to a `.tar.gz` archive in the containers directory.
- **Load from archive** — import a `.tar` or `.tar.gz` archive into the local Docker daemon via the Docker CLI or Sherpa's image import.

## Networking

Container networking uses two Docker network drivers:

### Management Network

A Docker **bridge** network provides management connectivity. All containers are attached to this network on their first interface (`eth0`) with an assigned IPv4 and IPv6 address. This network provides SSH access and ZTP communication with the server.

### Data Networks

By default, data plane links use Docker **macvlan** networks for Layer 2 connectivity:

| Mode | Description |
| ---- | ----------- |
| Passthru | Link interfaces. Each link has its own Linux bridge, passed straight through to one container. Pure L2, no IP addressing. |
| Bridge | [Private bridge](networking/modes/private-bridge.md) members, and unconnected interfaces. Several macvlan networks share one Linux bridge: the private bridge, or the node's isolated bridge. |

Links with `p2p = true` use a veth pair instead of macvlan. Once the container has started, Sherpa creates the veth with its container end already inside the container's network namespace, named, in promiscuous mode and up. The host end is joined to its peer by an [eBPF redirect program](networking/modes/point-to-point.md#p2p-ebpf). Nothing runs inside the container, so P2p links work with any image, including images without the `ip` command or without a shell. A container with such a link gets veth pairs for all its data interfaces: for a private bridge member, the host end joins the private bridge, and a disabled interface stays down with no carrier.

After attachment, data interfaces are set to promiscuous mode and brought up. Disabled interfaces (unconnected links) are left admin-down.

## Provisioning

Containers do not use traditional ZTP methods (TFTP, cloud-init). Instead, provisioning is handled through a combination of volume mounts, environment variables, and commands. The specific method varies by model — typically configuration files mounted as volumes, environment variables, or a combination of both.

### File Injection

Files can be injected into containers via volume mounts defined in the manifest:

- **`text_files`** — source file, destination path, owner, group, and permissions
- **`binary_files`** — binary artifacts mounted into the container
- **`volumes`** — arbitrary host-to-container path bindings

TLS certificates are automatically mounted when certificate paths are configured.

## Console Access

Container access is available through:

- **SSH** — connect via `sherpa ssh <node>` to nodes that run an SSH server
- **Docker exec** — attach to the container shell via `docker exec -it <container> <shell>`

## Lifecycle

| Operation | Description |
| --------- | ----------- |
| Create | Container is created and started with network attachments |
| Stop | Container is stopped gracefully |
| Resume | Stopped container is restarted |
| Redeploy | Container is killed and removed, then recreated with fresh configuration |
| Destroy | Container is killed (SIGKILL), removed, and associated Docker networks are cleaned up |
