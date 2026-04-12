# Manifest

A `Manifest` describes the lab configuration parameters.
Manifests are defined in the [toml](https://toml.io/en/) format in a file named `manifest.toml`
in the current directory.

## Example Manifest

```toml
# manifest.toml
name = "sexy-salamander"

nodes = [
  { name = "dev01", model = "sonic_linux" },
  { name = "dev02", model = "arista_ceos" },
]

links = [
  { src = "dev01::gig4", dst = "dev02::gig4" },
]
```

## Required Parameters

### Name
**string** - The name of the lab.

To avoid naming collisions, the `lab name` is hashed with the users `username`
to create a `lab-id`. Resources are suffixed with the `lab-id` to create unique resource names.

```toml
name = "sexy-salamander"
```

### Nodes
**list&lt;node_object&gt;** - The nodes that will be managed as part of this lab.

```toml
nodes = []
```

#### Required Node Parameters

- **name (string)**: The name of the device.
```toml
name = "dev01"
```

- **model (string)**: The model of the device.
```toml
model = "sonic_linux"
```

#### Optional Node Parameters

- **image (string)**: Custom image name to use instead of the default for this model.
```toml
image = "custom-ubuntu"
```

- **version (string)**: Specific image version to use instead of the default.
```toml
version = "22.04"
```

- **cpu_count (int)**: Configure the number of CPUs.
```toml
cpu_count = 4
```

- **memory (int)**: Configure the amount of RAM in `MegaBytes (MB)`.
```toml
memory = 4096
```

- **boot_disk_size (int)**: Change the size of the boot disk in `GigaBytes (GB)`.
```toml
boot_disk_size = 100
```

- **ipv4_address (string)**: Static IPv4 address for the management interface.
```toml
ipv4_address = "10.0.0.10"
```

- **ipv6_address (string)**: Static IPv6 address for the management interface.
```toml
ipv6_address = "fd00::10"
```

- **skip_ready_check (bool)**: Skip the node readiness check after deployment.
```toml
skip_ready_check = true
```

- **ztp_config (string)**: Path to a custom ZTP configuration file on the client.
```toml
ztp_config = "configs/dev01.txt"
```

- **startup_scripts (list&lt;string&gt;)**: A list of paths to scripts on the client
that will run on node startup.
```toml
startup_scripts = [
  "/path/to/script1.sh",
  "/path/to/script2.sh",
]
```

    _This parameter currently only applies to node models
    that support the `cloud-init` based ZTP method._

- **user_scripts (list&lt;string&gt;)**: A list of paths to user scripts on the client.
```toml
user_scripts = [
  "/path/to/user-script.sh",
]
```

- **commands (list&lt;string&gt;)**: A list of commands to execute at boot.
```toml
commands = [
  "apt-get update",
  "apt-get install -y curl",
]
```

    _This parameter currently only applies to node models
    that support the `cloud-init` based ZTP method._

- **environment_variables (list&lt;string&gt;)**: A list of environment variables to pass
to a node.
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

    _This parameter currently only applies to node models
    that support the `cloud-init` based ZTP method._

- **text_files (list&lt;object&gt;)**: A list of text files to pass to a node.
```toml
text_files = [
  { src = "~/.claude.json", dst = "/home/sherpa/.claude.json", user = "sherpa", group = "sherpa", permissions = 600 },
]
```

    _This parameter currently only applies to node models
    that support the `cloud-init` based ZTP method._

    !!! note
    The `dst` should be a fully qualified path.

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Source file path on the client |
| `dst` | string | Destination path on the node |
| `user` | string | File owner |
| `group` | string | File group |
| `permissions` | int | File permissions (e.g., `600`) |

- **binary_files (list&lt;object&gt;)**: A list of binary files to include with the node.
```toml
binary_files = [
  { source = "/path/to/binary" },
]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `source` | string | Source file path on the client |

- **systemd_units (list&lt;object&gt;)**: Systemd units to deploy to the node.
```toml
systemd_units = [
  { name = "myservice.service", source = "units/myservice.service", enabled = true },
]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `name` | string | Unit file name |
| `source` | string | Source file path on the client |
| `enabled` | bool | Whether to enable the unit |

- **ssh_authorized_keys (list&lt;string&gt;)**: SSH public keys to authorize on the node (inline).
```toml
ssh_authorized_keys = [
  "ssh-ed25519 AAAA... user@host",
]
```

- **ssh_authorized_key_files (list&lt;object&gt;)**: SSH public key file references.
```toml
ssh_authorized_key_files = [
  { source = "~/.ssh/id_ed25519.pub" },
]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `source` | string | Path to the public key file |

- **volumes (list&lt;object&gt;)**: Volume mounts for the node.
```toml
volumes = [
  { src = "/host/path", dst = "/container/path" },
]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Source path on the host |
| `dst` | string | Destination path in the node |

- **kernel_cmdline (string)**: Kernel command line arguments for DirectKernel unikernel nodes. Passed to QEMU via the libvirt `<cmdline>` XML element. Overrides any auto-injected command line.
```toml
kernel_cmdline = "/usr/bin/nginx"
```

    _This parameter only applies to unikernel nodes using the `direct_kernel` boot mode._

- **ready_port (int)**: TCP port to probe on the node's management IP to verify readiness. When set, Sherpa waits for a successful TCP connection to this port in addition to the libvirt domain reaching the running state.
```toml
ready_port = 80
```

    _This parameter only applies to unikernel nodes._

- **privileged (bool)**: Run the container in privileged mode.
```toml
privileged = true
```

- **shm_size (int)**: Shared memory size in bytes.
```toml
shm_size = 67108864
```

- **user (string)**: Default user for command execution.
```toml
user = "admin"
```

## Optional Parameters

### Ready Timeout

**int** - Global timeout in seconds for node readiness checks. Overrides the default timeout for all nodes in the lab.

```toml
ready_timeout = 300
```

### Links

**list&lt;link_object&gt;** - Links define the connectivity relationship between nodes in the topology.

Each device is defined with its `name` and `interface` separated by a double colon `(::)`

```toml
links = [
  { src = "dev01::eth0", dst = "dev02::eth1" },
]
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
links = [
  { src = "dev01::eth1", dst = "dev02::eth1", impairment = { delay = 50, jitter = 10, loss_percent = 1.0 } },
]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `delay` | int | One-way delay in milliseconds |
| `jitter` | int | Delay jitter in milliseconds |
| `loss_percent` | float | Packet loss percentage (`0.0` - `100.0`) |
| `reorder_percent` | float | Packet reordering percentage (`0.0` - `100.0`) |
| `corrupt_percent` | float | Bit-flip corruption percentage (`0.0` - `100.0`) |

For more information on link types see the [point-to-point](architecture/networking/node/point-to-point.md) architecture documentation.

### Bridges

**list&lt;bridge_object&gt;** - Bridges define shared layer 2 network segments that connect multiple node interfaces.

Unlike [links](#links) which create point-to-point connections between two nodes, bridges allow
three or more interfaces to share a common network segment.

Each bridge link is defined with the node `name` and `interface` separated by a double colon `(::)`

```toml
bridges = [
  { name = "shared", links = ["dev01::eth2", "dev02::eth2", "dev03::eth1"] },
]
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `name` | string | A user-friendly name for the bridge |
| `links` | list&lt;string&gt; | A list of `<device>::<interface>` mappings to connect to the bridge |

For more information on bridge types see the [private-bridge](architecture/networking/node/private-bridge.md) architecture documentation.

### ZTP Server

**object** - Configure the Zero-Touch Provisioning server settings.

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

### Configuration Management

**object** - Enable configuration management tool integrations. When enabled, Sherpa generates inventory files for the specified tools.

```toml
[config_management]
ansible = true
pyats = false
nornir = false
```

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `ansible` | bool | `false` | Generate Ansible inventory |
| `pyats` | bool | `false` | Generate pyATS testbed |
| `nornir` | bool | `false` | Generate Nornir inventory |
