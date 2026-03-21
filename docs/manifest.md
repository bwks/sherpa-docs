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

To avoid naming collisions, the `lab name` is hashed with the users, `username`
to create a `lab-id`. Resources are suffixed with the `lab-id` to create unique resource names.

```toml
name = "sexy-salamander"
```

### Nodes
**list&lt;node_object&gt;** - The nodes that will be managed as part of this lab.

```toml
nodes = []
```

#### Required Parameters
Node object `required` parameters.

- **name (string)**: The name of the device.
```toml
name = "dev01"
```

- **model (string)**: The model of the device.
```toml
model = "sonic_linux"
```

#### Optional Parameters
Node object `optional` parameters.

- **cpu_count (int)**: Configure the number of CPU's.
```toml
cpu_count = 4
```

- **memory (int)**: Configure the amount of RAM `MegaBytes (MB)`.
```toml
memory = 4096
```

- **boot_disk_size (int)**: Change the size of the  boot disk in `GigaBytes (GB)`.
```toml
boot_disk_size = 100
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

## Optional Paramters

### Links

**list&lt;link_object&gt;** - Links define the connectivity relationship between nodes in the topology.

Each device is defined with it's `name` and `interface` separated by a double colon `(::)`

- **src (string)**: Source `<device>::<interface>` mapping.
- **dst (string)**: Destination `<device>::<interface>` mapping.

```toml
links = [
  { src = "dev01::eth0", dst = "dev02::eth1" },
]
```

For more information on bridge types see the node [point-to-point](architecture/networking/node/point-to-point.md) architecture documentation.

### Bridges

**list&lt;bridge_object&gt;** - Bridges define shared layer 2 network segments that connect multiple node interfaces.

Unlike [links](#links) which create point-to-point connections between two nodes, bridges allow
three or more interfaces to share a common network segment.

Each bridge link is defined with the node `name` and `interface` separated by a double colon `(::)`

- **name (string)**: A user-friendly name for the bridge.
- **links (list&lt;string&gt;)**: A list of `<device>::<interface>` mappings to connect to the bridge.

```toml
bridges = [
  { name = "shared", links = ["dev01::eth2", "dev02::eth2", "dev03::eth1"] },
]
```

For more information on bridge types see the node [private-bridge](architecture/networking/node/private-bridge.md) architecture documentation.