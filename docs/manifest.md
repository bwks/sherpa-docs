# Manifest

A `Manifest` describes the lab configuration parameters.
Manifests are defined in the [toml](https://toml.io/en/) format in a file named `manifest.toml`
in the current directory.

## Example Manifest

```toml
# manifest.toml
name = "sexy-salamander"

[[nodes]]
name = "dev01"
model = "sonic_linux"

[[nodes]]
name = "dev02"
model = "arista_ceos"

[[links]]
src = "dev01::gig4"
dst = "dev02::gig4"
```

## Required Parameters

### name (string)

The name of the lab.

To avoid naming collisions, the `lab name` is hashed with the users `username`
to create a `lab-id`. Resources are suffixed with the `lab-id` to create unique resource names.

```toml
name = "sexy-salamander"
```

### nodes (list&lt;node_object&gt;)

The nodes that will be managed as part of this lab.

```toml
nodes = []
```

#### Required Node Parameters

##### name (string)

The name of the device.

```toml
name = "dev01"
```

##### model (string)

The model of the device.

```toml
model = "sonic_linux"
```

#### Optional Node Parameters

##### binary_files (list&lt;object&gt;)

A list of binary files to include with the node.

```toml
[[nodes.binary_files]]
source = "/path/to/binary"
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `source` | string | Source file path on the client |

##### boot_disk_clone_method (string)

How a virtual machine's boot disk is created from the base image. Supported values:

| Value | Description |
| ----- | ----------- |
| `overlay` | Default. Creates a small disk that stores only the changes from the base image. Fast to create and uses little space. |
| `copy` | Creates an independent full copy of the base image. |

```toml
boot_disk_clone_method = "copy"
```

Use `copy` when you need a disk that does not depend on the base image, or when the
base image cannot be used for overlays. See [Storage](architecture/storage.md#boot-disk-overlays).

_This parameter only applies to virtual machine nodes. Setting `overlay` on a container or
unikernel node is an error. It cannot be set at the lab level._

##### boot_disk_size (int)

Change the size of the boot disk in `GigaBytes (GB)`.

If omitted, the disk is the same size as the base image. The size can equal or exceed the base
image, but cannot shrink it.

```toml
boot_disk_size = 100
```

##### commands (list&lt;string&gt;)

A list of commands to execute at boot.

```toml
commands = [
  "apt-get update",
  "apt-get install -y curl",
]
```

_This parameter currently only applies to node models
that support the `cloud-init` based ZTP method._

##### cpu_count (int)

Configure the number of CPUs.

```toml
cpu_count = 4
```

##### data_interface_count (int)

Number of data interfaces to create for this node. Overrides the default for the node model.

```toml
data_interface_count = 4
```

The count covers data interfaces only. The management interface and any interfaces reserved
by the model are not included. Requesting more interfaces than the model supports fails
manifest validation.

##### environment_variables (list&lt;string&gt;)

A list of environment variables to pass to a node.

```toml
environment_variables = [
  # Supply the token inline. Beware, this is very insecure for sensitive vars.
  "SOME_VAR1=hello_jimmy",
  "MUSICAL_GENIUS='xyz-to-da-1-2-3'",
  # Load variable from your client environment with a dollar sign ($) prefixed variable name.
  "GH_TOKEN=$GH_TOKEN",
  "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY",
]
```

Where the variables are set depends on the node:

- **Linux and BSD VMs using `cloud-init`, and Flatcar**: the variables are written to
  `~/.sherpa_env` in the home directory of the login user, which is your personal account
  when [`provision_current_user`](#provision_current_user-bool) is enabled, otherwise the
  `sherpa` user. The file is readable only by that user, and nothing is written system-wide.
  A line that sources it is added to `~/.bash_profile`, or to `~/.profile` when there is no
  `~/.bash_profile`, so the variables are set in login shells, including
  [`user_scripts`](#user_scripts-liststring).
- **Windows VMs**: the variables are set machine-wide.
- **Containers**: the variables are set in the container environment.

!!! note
    On VMs, the variables are not set in non-login sessions, such as `ssh <node> <command>`,
    cron jobs and systemd services, or in `startup_scripts`, which run as root. If your
    dotfiles replace `~/.bash_profile` or `~/.profile`, keep this line in them:

    ```sh
    if [ -r "$HOME/.sherpa_env" ]; then . "$HOME/.sherpa_env"; fi
    ```

##### image (string)

Custom image name to use instead of the default for this model.

```toml
image = "custom-ubuntu"
```

##### kernel_cmdline (string)

Kernel command line arguments for DirectKernel unikernel nodes. Passed to QEMU via the libvirt `<cmdline>` XML element. Overrides any auto-injected command line.

```toml
kernel_cmdline = "/usr/bin/nginx"
```

_This parameter only applies to unikernel nodes using the `direct_kernel` boot mode._

##### memory (int)

Configure the amount of RAM in `MegaBytes (MB)`.

```toml
memory = 4096
```

##### privileged (bool)

Run the container in privileged mode.

```toml
privileged = true
```

##### ready_port (int)

TCP port to probe on the node's management IP to verify readiness.

- **Virtual machines:** replaces the model's readiness port. Most models are checked on SSH
  port `22`; `talos_linux` is checked on the Talos API port `50000`.
- **Unikernels:** Sherpa waits for a TCP connection to this port in addition to the libvirt
  domain reaching the running state.

```toml
ready_port = 80
```

_This parameter does not apply to container nodes._

##### shm_size (int)

Shared memory size in bytes.

```toml
shm_size = 67108864
```

##### skip_ready_check (bool)

Skip the node readiness check after deployment and after `sherpa resume`.

```toml
skip_ready_check = true
```

##### ssh_authorized_key_files (list&lt;object&gt;)

SSH public key file references.

```toml
[[nodes.ssh_authorized_key_files]]
source = "~/.ssh/id_ed25519.pub"
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `source` | string | Path to the public key file |

##### ssh_authorized_keys (list&lt;string&gt;)

SSH public keys to authorize on the node (inline).

```toml
ssh_authorized_keys = [
  "ssh-ed25519 AAAA... user@host",
]
```

##### startup_scripts (list&lt;string&gt;)

A list of paths to scripts on the client that will run on node startup.

```toml
startup_scripts = [
  "/path/to/script1.sh",
  "/path/to/script2.sh",
]
```

_This parameter currently only applies to node models
that support the `cloud-init` based ZTP method._

Startup scripts run as root. Each script is run directly, so start it with a shebang line,
such as `#!/bin/bash`, to choose its interpreter. A script without one runs with the node's
`/bin/sh`. Alpine, FreeBSD and OpenBSD do not ship Bash, so use `#!/bin/sh` there.

##### systemd_units (list&lt;object&gt;)

Systemd units to deploy to the node.

```toml
[[nodes.systemd_units]]
name = "myservice.service"
source = "units/myservice.service"
enabled = true
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `name` | string | Unit file name |
| `source` | string | Source file path on the client |
| `enabled` | bool | Whether to enable the unit |

##### text_files (list&lt;object&gt;)

A list of text files to pass to a node.

```toml
[[nodes.text_files]]
src = "~/.claude.json"
dst = "/home/sherpa/.claude.json"
user = "sherpa"
group = "sherpa"
permissions = 600
```

_This parameter currently only applies to node models
that support the `cloud-init` based ZTP method._

!!! note
    The `dst` should be a fully qualified path.

!!! note
    Text files are written late in the first boot, after cloud-init has created
    users, so `user` and `group` can name the `sherpa` user. They must name a user
    and group that exist on the node, otherwise cloud-init does not write the file.

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Source file path on the client |
| `dst` | string | Destination path on the node |
| `user` | string | File owner |
| `group` | string | File group |
| `permissions` | int | File permissions (e.g., `600`) |

##### user (string)

Default user for command execution.

```toml
user = "admin"
```

##### user_scripts (list&lt;string&gt;)

A list of paths to user scripts on the client.

```toml
user_scripts = [
  "/path/to/user-script.sh",
]
```

User scripts run at the end of the first boot, as your personal account when
[`provision_current_user`](#provision_current_user-bool) is enabled, otherwise as the
`sherpa` user. They run in a login shell, so `environment_variables` are set. Like
[`startup_scripts`](#startup_scripts-liststring), each script is run directly, so its shebang
line chooses the interpreter.

##### version (string)

Specific image version to use instead of the default.

```toml
version = "22.04"
```

##### volumes (list&lt;object&gt;)

Volume mounts for the node.

```toml
[[nodes.volumes]]
src = "/host/path"
dst = "/container/path"
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Source path on the host |
| `dst` | string | Destination path in the node |

##### ztp_config (string)

Path to a custom ZTP configuration file on the client.

```toml
ztp_config = "configs/dev01.txt"
```

Nodes that join a [Talos cluster](#talos_clusters-listtalos_cluster_object) cannot set
`ztp_config`: Sherpa generates their machine configs.

## Optional Parameters

### bridges (list&lt;bridge_object&gt;)

Bridges define shared layer 2 network segments that connect multiple node interfaces.

Unlike [links](#links-listlink_object) which create point-to-point connections between two nodes, bridges allow
three or more interfaces to share a common network segment.

Each bridge link is defined with the node `name` and `interface` separated by a double colon `(::)`

```toml
[[bridges]]
name = "shared"
links = ["dev01::eth2", "dev02::eth2", "dev03::eth1"]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `name` | string | A user-friendly name for the bridge |
| `links` | list&lt;string&gt; | A list of `<device>::<interface>` mappings to connect to the bridge |

For more information on bridge types see the [private-bridge](architecture/networking/modes/private-bridge.md) architecture documentation.

### description (string)

A short description of the lab's purpose. Optional.

```toml
name = "bgp-practice"
description = "Practice BGP peering and route policies between two routers."
```

Multiline strings and Unicode are supported.

### links (list&lt;link_object&gt;)

Links define the connectivity relationship between nodes in the topology.

Each device is defined with its `name` and `interface` separated by a double colon `(::)`

```toml
[[links]]
src = "dev01::eth0"
dst = "dev02::eth1"
```

#### Link Properties

| Property | Type | Required | Description |
| -------- | ---- | -------- | ----------- |
| `src` | string | yes | Source `<device>::<interface>` mapping |
| `dst` | string | yes | Destination `<device>::<interface>` mapping |
| `p2p` | bool | no | Enable point-to-point link mode (default: `false`) |
| `impairment` | object | no | Network impairment configuration |

#### Link Impairment

Apply network impairment to simulate real-world link conditions.

```toml
[[links]]
src = "dev01::eth1"
dst = "dev02::eth1"

[links.impairment]
delay = 50
jitter = 10
loss_percent = 1.0
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `delay` | int | One-way delay in milliseconds |
| `jitter` | int | Delay jitter in milliseconds |
| `loss_percent` | float | Packet loss percentage (`0.0` - `100.0`) |
| `reorder_percent` | float | Packet reordering percentage (`0.0` - `100.0`) |
| `corrupt_percent` | float | Bit-flip corruption percentage (`0.0` - `100.0`) |

For more information on link types see the [point-to-point](architecture/networking/modes/point-to-point.md) architecture documentation.

### provision_current_user (bool)

Create an account for the lab owner on supported Linux VMs, using the owner's Sherpa username
and registered SSH public keys. Defaults to `false`.

```toml
provision_current_user = true
```

See [Personal Accounts](architecture/personal-accounts.md). A node with a custom `ztp_config`
cannot be used with this setting.

### ready_timeout (int)

Global timeout in seconds for node readiness checks. Overrides the default timeout for all nodes in the lab.
It applies to `sherpa up`, `sherpa redeploy` and `sherpa resume`.

```toml
ready_timeout = 300
```

### tailscale (object)

Connect the lab's management networks to the owner's Tailscale tailnet through
a dedicated gateway. Nodes do not need their own Tailscale agent.

```toml
[tailscale]
enabled = true
auth_key_env = "SHERPA_TAILSCALE_KEY"
```

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enabled` | bool | `false` | Create a Tailscale gateway for the lab |
| `auth_key_env` | string | unset | Client environment variable containing the auth key; required when enabled |

Set the named variable in the client shell before running `sherpa up`. Store only
the variable name in the manifest, never the key. The key is required only for
initial creation; stop and resume retain the gateway identity. Omitting the section
or setting `enabled = false` requires no credential and creates no gateway.

Enrollment requires server TLS and WSS with certificate validation enabled.
Route approval is separate from enrollment; pending approval produces a warning
without failing lab creation. See [Tailscale setup and route approval](architecture/networking/tailscale.md).

### talos_clusters (list&lt;talos_cluster_object&gt;)

Kubernetes clusters built from the lab's [Talos Linux](nodes/linux/talos-linux.md) nodes. Each
cluster lists its member nodes by name. Sherpa generates each cluster's secrets and machine
configs, bootstraps it, and writes a `kubeconfig-<cluster>` and `talosconfig-<cluster>` to your
working directory.

```toml
[[talos_clusters]]
name = "k8s"
controllers = ["cp01", "cp02", "cp03"]
workers = ["worker01"]

[[nodes]]
name = "cp01"
model = "talos_linux"

[[nodes]]
name = "cp02"
model = "talos_linux"

[[nodes]]
name = "cp03"
model = "talos_linux"

[[nodes]]
name = "worker01"
model = "talos_linux"
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `name` | string | Cluster name, also the Kubernetes cluster name. 1–63 lowercase letters, digits or `-` |
| `controllers` | list&lt;string&gt; | Nodes that run etcd and the Kubernetes control plane. Sherpa bootstraps the cluster on the first one |
| `workers` | list&lt;string&gt; | Nodes that run workloads only. Optional; without workers, workloads run on the controllers |

Members must be `talos_linux` nodes defined in [`nodes`](#nodes-listnode_object), and a node can
be listed only once across all clusters. A `talos_linux` node that is not listed is a standalone
Talos node.

Each cluster needs one or three controllers. Two are refused: etcd needs a majority of its
members to stay up, so two controllers survive no failure and are less available than one.
A lab can have several clusters; at most two of them can have three controllers.

### ztp_server (object)

Configure the Zero-Touch Provisioning server settings.

```toml
[ztp_server]
enable = true
username = "sherpa"
password = "sherpa"
```

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enable` | bool | `true` | Enable or disable the ZTP server |
| `username` | string | `"sherpa"` | Username for ZTP authentication |
| `password` | string | `"sherpa"` | Password for ZTP authentication |
