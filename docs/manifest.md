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

The name of the device: 1 to 63 letters, digits, `-` or `_`, starting with a letter or digit.
It becomes the node's host name, so it cannot contain dots, spaces or other characters.

```toml
name = "dev01"
```

##### model (string)

The model of the device.

```toml
model = "sonic_linux"
```

#### Optional Node Parameters

A node's settings are grouped. A few are top-level keys of the node; the rest sit in a table
named after their group, such as `[nodes.cpu]`. Every setting is optional: one left out keeps
the value of the node's image. A key Sherpa does not know is refused, including the flat keys
of earlier releases (see [Upgrading manifests](#upgrading-manifests-from-flat-keys)).

```toml
[[nodes]]
name = "dev01"
model = "ubuntu_linux"
memory = 4096

[nodes.cpu]
count = 4

[nodes.interfaces]
data_count = 4

[nodes.ready_check]
skip = true
```

TOML also takes a group's keys inline or as dotted keys, so `cpu = { count = 4 }` and
`cpu.count = 4` are the same as the `[nodes.cpu]` table above. Each group may appear once per
node.

| Group | Keys |
|---|---|
| [`cpu`](#cpu-object) | `count`, `mode`, `topology`, `pinning`, `emulator_pinning` |
| [`numa`](#numa-object) | `node`, `memory_mode` |
| [`boot_disk`](#boot_disk-object) | `size`, `clone_method`, `cache`, `io`, `io_thread_cpus` |
| [`interfaces`](#interfaces-object) | `data_count`, `queues` |
| [`ztp`](#ztp-object) | `method`, `config` |
| [`ssh`](#ssh-object) | `authorized_keys`, `authorized_key_files` |
| [`ready_check`](#ready_check-object) | `port`, `skip` |
| [`vm`](#vm-object) | `watchdog` |
| [`container`](#container-object) | `user`, `privileged`, `shm_size`, `commands`, `volumes`, `platform` |
| [`unikernel`](#unikernel-object) | `cmdline` |

##### Which node kinds take which settings

Sherpa refuses a setting the node's kind does not take, and a `vm`, `container` or `unikernel`
group on a node of another kind. The message names the node, the key and the kind, for example
``Manifest - node: 'web01' sets `container`, which does not apply to virtual_machine nodes``.

| Setting | Virtual machine | Container | Unikernel |
|---|---|---|---|
| `memory`, `cpu.count` | yes | yes (see note) | yes |
| `cpu.mode`, `cpu.topology`, `cpu.pinning`, `cpu.emulator_pinning` | yes | | |
| `numa` | yes | | |
| `boot_disk.size` | yes | | yes |
| `boot_disk.clone_method`, `boot_disk.cache`, `boot_disk.io`, `boot_disk.io_thread_cpus` | yes | | |
| `interfaces.data_count` | yes | yes | yes |
| `interfaces.queues` | yes | | |
| `ztp`, `ssh` | yes | yes | |
| `ready_check.port` | yes | | yes |
| `ready_check.skip` | yes | yes | yes |
| `environment_variables`, `text_files`, `binary_files`, `systemd_units`, `startup_scripts`, `user_scripts` | yes | yes | |
| `vm` | yes | | |
| `container` | | yes | |
| `unikernel` | | | yes |

!!! note "CPU and memory on containers"
    Containers accept `cpu.count` and `memory`, but only `juniper_cevolved` uses them, to size
    the router VM inside the container. Other containers run without CPU or memory limits.

Within a kind, a setting may still apply only to some models or ZTP methods; each section below
says so.

##### binary_files (list&lt;object&gt;)

Binary files to copy onto a Flatcar Linux node's data disk, at its root. The `sherpa` CLI reads
each file on your machine and sends it to the server, which never reads paths from a manifest.
A relative path starts at the manifest's folder.

```toml
[[nodes.binary_files]]
source = "bin/tool"
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `source` | string | Path of the file on the client. Its file name is kept, and cannot start with `-` |

##### environment_variables (list&lt;string&gt;)

A list of environment variables to pass to a node.

```toml
environment_variables = [
  "SOME_VAR1=hello_jimmy",
  "MUSICAL_GENIUS='xyz-to-da-1-2-3'",
  # Load variable from your client environment with a dollar sign ($) prefixed variable name.
  "GIT_AUTHOR_NAME=$GIT_AUTHOR_NAME",
]
```

!!! warning "Not for secrets"
    Do not put passwords, API keys or tokens in `environment_variables`, `text_files`,
    `startup_scripts` or `user_scripts`. Their contents are sent to the Sherpa server, which
    stores them with the lab: in the saved manifest, the node's generated configuration and its
    first-boot media. Sherpa server administrators can read them there. Values loaded from your
    client environment with `$` are stored the same way. For containers, environment variables
    also appear in `docker inspect` on the server.

    Use [`provisioners`](#provisioners-listobject) for secrets. On virtual machines the CLI
    copies them to the node itself, so the server never sees them; containers get them as files
    the server keeps in memory only.

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

For a container node, `image` is the image repository without a tag: the node's version is the
tag. It replaces the repo the version was pulled from, for every container model, including those
with a built-in repo. `sherpa up` and `sherpa redeploy` check that Docker has `<image>:<version>`
and fail if it does not, before they create anything.

##### memory (int)

Configure the amount of RAM in `MegaBytes (MB)`.

```toml
memory = 4096
```

The server refuses to start virtual machines and unikernels whose memory does not fit beside
the memory already promised on the server. See [`[host_memory]`](configuration/sherpa.md#host_memory).

##### provisioners (list&lt;object&gt;)

Provisioners get secrets onto the node, run by the `sherpa` CLI. They are never saved with the
lab. There are two types: `ssh` for Linux and BSD virtual machines, and `container` for
containers. See [Provisioners](architecture/provisioners/overview.md) for how they work and when
they run.

```toml
[[nodes.provisioners]]
type = "ssh"
env_files = ["secrets/dev.env"]
scripts = ["secrets/setup.sh"]

[[nodes.provisioners.files]]
src = "~/.config/gh/hosts.yml"
dst = "~/.config/gh/hosts.yml"
mode = 600
```

_Provisioners run only from the `sherpa` CLI. A manifest with provisioners is refused from the
web UI and the REST API._

[`ssh`](architecture/provisioners/ssh.md) provisioner properties, for Linux and BSD virtual
machines:

| Property | Type | Description |
| -------- | ---- | ----------- |
| `type` | string | `ssh` |
| `files` | list&lt;object&gt; | Files copied to the node over SFTP |
| `env_files` | list&lt;string&gt; | Env files copied to `~/.env.d/`, which login shells load. A value of exactly `$NAME` or `${NAME}` is replaced with that variable from your environment |
| `scripts` | list&lt;string&gt; | Scripts run on the node, through their shebang line |

The SSH provisioner runs as the node's login user, in this order: `files`, `env_files`, then
`scripts`. Client paths expand `~`, and relative paths start at the manifest's folder.

`files` properties:

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Path on the client |
| `dst` | string | Path on the node: absolute, or starting with `~/` for the login user's home. Letters, digits and `. _ - + @` only |
| `mode` | int | File permissions (e.g., `600`). Defaults to `600` |

A file is written with its `mode` from the start and replaces any file at `dst` in one step, so
it is never more readable than `mode` allows, and a failed copy leaves the old file as it was.
Missing folders on the way to `dst` are created readable only by the login user.

Env files hold `KEY=value` lines and are copied as `~/.env.d/<file name>`, so two env files on a
node cannot share a name. Scripts get the variables from `environment_variables` and
`~/.env.d/`.

[`container`](architecture/provisioners/container.md) provisioner, for containers: secret
files, mounted read-only at `/run/secrets/<name>` before the container starts.

```toml
[[nodes]]
name = "db01"
model = "mongo_db"
environment_variables = [
  "MONGO_INITDB_ROOT_USERNAME=admin",
  "MONGO_INITDB_ROOT_PASSWORD_FILE=/run/secrets/mongo_password",
]

[[nodes.provisioners]]
type = "container"

[[nodes.provisioners.files]]
src = "secrets/mongo-password"
name = "mongo_password"
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `type` | string | `container` |
| `files` | list&lt;object&gt; | Secret files |

`files` properties:

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Path on the client |
| `name` | string | File name in `/run/secrets`. Letters, digits and `. _ - + @` only |
| `mode` | int | File permissions (e.g., `400`). Defaults to `444`, so a container that does not run as root can read it |

Many images read a secret from a file named in a `*_FILE` environment variable, as above.

##### startup_scripts (list&lt;string&gt;)

A list of paths to scripts on the client that will run on node startup. A path may start
with `~`; a relative path starts at the manifest's folder.

```toml
startup_scripts = [
  "/path/to/script1.sh",
  "/path/to/script2.sh",
]
```

_This parameter currently only applies to node models
that support the `cloud-init` based ZTP method._

Like [`environment_variables`](#environment_variables-liststring), startup scripts are
stored on the Sherpa server and are not for secrets.

Startup scripts run as root. Each script is run directly, so start it with a shebang line,
such as `#!/bin/bash`, to choose its interpreter. A script without one runs with the node's
`/bin/sh`. Alpine, FreeBSD and OpenBSD do not ship Bash, so use `#!/bin/sh` there.

##### systemd_units (list&lt;object&gt;)

Systemd units to deploy to a Flatcar Linux node. The `sherpa` CLI reads each unit file on your
machine and sends its contents. A relative path starts at the manifest's folder.

```toml
[[nodes.systemd_units]]
name = "myservice.service"
source = "units/myservice.service"
enabled = true
```

| Property | Type | Description |
| -------- | ---- | ----------- |
| `name` | string | Unit file name, such as `app.service`. It cannot contain `/` or start with `-` |
| `source` | string | Path of the unit file on the client |
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

!!! warning
    Text files are stored on the Sherpa server and are not for secrets. See
    [`environment_variables`](#environment_variables-liststring).

!!! note
    Text files are written late in the first boot, after cloud-init has created
    users, so `user` and `group` can name the `sherpa` user. They must name a user
    and group that exist on the node, otherwise cloud-init does not write the file.

!!! note "Windows nodes"
    Windows has no file modes, so `user`, `group` and `permissions` are not applied as on
    Linux. A file whose `permissions` give others no access (such as `600` or `640`) can be
    read only by Administrators and SYSTEM. Any other file takes the access of the folder it
    is written to, which on most folders lets every local user read it. The `dst` cannot
    contain `"` or `%`.

| Property | Type | Description |
| -------- | ---- | ----------- |
| `src` | string | Source file path on the client |
| `dst` | string | Destination path on the node |
| `user` | string | File owner |
| `group` | string | File group |
| `permissions` | int | File permissions as octal digits (e.g., `600`), up to `777`. `sherpa validate` and `sherpa up` refuse other values. Write the digits as a plain number: `0644` is not valid TOML, and TOML's octal literal `0o644` is the number 420, which Sherpa reads as mode `420` |

##### user_scripts (list&lt;string&gt;)

A list of paths to user scripts on the client. A path may start with `~`; a relative path
starts at the manifest's folder.

```toml
user_scripts = [
  "/path/to/user-script.sh",
]
```

User scripts are stored on the Sherpa server and are not for secrets. See
[`environment_variables`](#environment_variables-liststring).

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

##### cpu (object)

The node's virtual CPUs: how many, and for a virtual machine how they are presented and which
host CPUs they run on.

```toml
[nodes.cpu]
count = 4
mode = "host-passthrough"
topology = { sockets = 1, cores = 2, threads = 2 }
pinning = [9, 25, 10, 26]
emulator_pinning = [8, 24]
```

| Key | Type | Description |
|---|---|---|
| `count` | int | The number of vCPUs, in place of the image's |
| `mode` | string | `host-model` (the default) or `host-passthrough`, which gives the guest the host CPU exactly. `host-passthrough` gives the best performance for nested virtual machines |
| `topology` | object | The CPU layout the guest sees: `sockets`, `cores` and `threads`. Their product must equal `count` |
| `pinning` | list&lt;int&gt; | The host CPU for each vCPU, in vCPU order: one per vCPU, none repeated |
| `emulator_pinning` | list&lt;int&gt; | Host CPUs for QEMU's own threads, everything in the virtual machine's QEMU process except its vCPUs |

`mode`, `topology`, `pinning` and `emulator_pinning` apply only to virtual machines. See
[Tuning a virtual machine](#tuning-a-virtual-machine) for the rules on pinned host CPUs.

##### numa (object)

The host NUMA node a virtual machine's memory is placed on.

```toml
[nodes.numa]
node = 1
memory_mode = "preferred"
```

| Key | Type | Description |
|---|---|---|
| `node` | int | The host NUMA node the guest's memory is placed on. How strictly is set by `memory_mode` |
| `memory_mode` | string | `strict` (the default) or `preferred`. `strict` keeps the memory on `node` even when that node is full. `preferred` uses `node` first and other nodes when it is full. Needs `node` |

_This group only applies to virtual machine nodes._

##### boot_disk (object)

The disk the node boots from: its size, and for a virtual machine how it is created and how
QEMU does its I/O.

```toml
[nodes.boot_disk]
size = 100
clone_method = "copy"
cache = "none"
io = "native"
io_thread_cpus = [8, 24]
```

| Key | Type | Description |
|---|---|---|
| `size` | int | The boot disk's size in `GigaBytes (GB)`. If omitted, the disk is the same size as the base image. The size can equal or exceed the base image, but cannot shrink it |
| `clone_method` | string | How the boot disk is created from the base image: `overlay` or `copy`, see below |
| `cache` | string | The host cache mode for the disks: `none`, `writeback` or `writethrough` |
| `io` | string | How QEMU submits disk I/O: `native`, `io_uring` or `threads`. `native` needs `cache = "none"` |
| `io_thread_cpus` | list&lt;int&gt; | Give the disks their own I/O thread, pinned to these host CPUs. Needs virtio disks |

`clone_method` values:

| Value | Description |
| ----- | ----------- |
| `overlay` | Default. Creates a small disk that stores only the changes from the base image. Fast to create and uses little space. |
| `copy` | Creates an independent full copy of the base image. |

Use `copy` when you need a disk that does not depend on the base image, or when the
base image cannot be used for overlays. See [Storage](architecture/storage.md#boot-disk-overlays).
`clone_method` cannot be set at the lab level.

`size` applies to virtual machines and to unikernels that boot from a disk (`disk_boot`, such
as Nanos). `clone_method`, `cache`, `io` and `io_thread_cpus` apply only to virtual machines.

##### interfaces (object)

The node's data interfaces.

```toml
[nodes.interfaces]
data_count = 4
queues = 4
```

| Key | Type | Description |
|---|---|---|
| `data_count` | int | The number of data interfaces, in place of the model's default |
| `queues` | int | virtio-net queues on each interface, from 1 to `cpu.count`. Needs virtio interfaces; the management interface gets them only if it is virtio too |

`data_count` covers data interfaces only. The management interface and any interfaces reserved
by the model are not included. Requesting more interfaces than the model supports fails
manifest validation.

`queues` applies only to virtual machines, and needs `cpu.count` to be set.

##### ztp (object)

The node's zero touch provisioning.

```toml
[nodes.ztp]
method = "disabled"
config = "configs/dev01.txt"
```

| Key | Type | Description |
|---|---|---|
| `method` | string | The node's [ZTP setting](architecture/zero-touch-provisioning.md#the-ztp-setting), in place of its image's: `disabled`, or one of `cloud-init`, `cdrom`, `disk`, `http`, `ignition`, `nocloud`, `tftp`, `usb` and `volume` |
| `config` | string | Path to a custom ZTP configuration file on the client. It may start with `~`; a relative path starts at the manifest's folder |

`method` must be `disabled` or a method the node's model takes; `sherpa validate` reports any
other. Most models take one method, so the key is mostly used to turn ZTP off for a node.
Without it, the node uses its image's setting.

Only nodes whose ZTP setting is `tftp`, `nocloud`, `cdrom`, `disk`, `usb` or `volume` take a
`config`, and a `hashicorp_vault` node, where it is Vault's own configuration file. Sherpa
refuses it on any other node, including one whose ZTP is `disabled`.

Nodes that join a [Talos cluster](#talos_clusters-listtalos_cluster_object) cannot set
`method = "disabled"` or a `config`: Sherpa generates their machine configs.

_This group applies to virtual machine and container nodes._

##### ssh (object)

SSH public keys to authorize on the node.

```toml
[nodes.ssh]
authorized_keys = [
  "ssh-ed25519 AAAA... user@host",
]
authorized_key_files = [
  { source = "~/.ssh/id_ed25519.pub" },
]
```

| Key | Type | Description |
|---|---|---|
| `authorized_keys` | list&lt;string&gt; | Public keys, inline |
| `authorized_key_files` | list&lt;object&gt; | Public key files whose keys to authorize on a Flatcar Linux node. Each has a `source`: the path of the public key file on the client |

The `sherpa` CLI reads each key file on your machine and sends the key; the server checks it and
never reads the path. A relative path starts at the manifest's folder.

_This group applies to virtual machine and container nodes._

##### ready_check (object)

How Sherpa decides the node is ready after `sherpa up`, `sherpa redeploy` and `sherpa resume`.

```toml
[nodes.ready_check]
port = 80
skip = false
```

| Key | Type | Description |
|---|---|---|
| `port` | int | Port to probe on the node's management IP. Virtual machines and unikernels only |
| `skip` | bool | Skip the readiness check |

`port`:

- **Virtual machines:** replaces the model's readiness port. Most models are checked on SSH
  port `22`; `talos_linux` is checked on the Talos API port `50000`. On port `22` an SSH
  server must answer: the port must be open and complete an SSH handshake (no login is
  attempted). Any other port only needs to accept a TCP connection.
- **Unikernels:** Sherpa waits for a TCP connection to this port in addition to the libvirt
  domain reaching the running state.
- **Containers** have no port check: a container is ready once it keeps running. Sherpa
  refuses `port` on a container.

With `skip = true` the node is still created and started; Sherpa just doesn't wait for it to be
ready. A container is not waited for to keep running, but one that is not running right after
it starts is still reported as a failed node, with its exit code and last log lines, and
`sherpa up` exits with an error.

##### vm (object)

Settings only a virtual machine takes.

```toml
[nodes.vm]
watchdog = "reset"
```

| Key | Type | Description |
|---|---|---|
| `watchdog` | string | Give the virtual machine a hardware watchdog, and choose what happens when it expires. Without it, Sherpa adds none |

`watchdog` actions:

| Action | What happens when the watchdog expires |
|---|---|
| `reset` | The VM is reset, as with the reset button |
| `poweroff` | The VM is powered off at once |
| `shutdown` | The guest is asked to shut down, as with the power button |
| `pause` | The VM is paused |
| `dump` | The VM's memory is dumped, and it keeps running |
| `inject-nmi` | The guest receives a non-maskable interrupt |
| `none` | Nothing; the device is present but has no effect |

The watchdog is an emulated Intel 6300ESB timer. It does nothing until the guest starts it, and
the guest must then keep resetting it: if the guest hangs and stops, the action is taken. It
helps only guests that run a watchdog driver and something that feeds it, for example Linux with
the `i6300esb` module and systemd's `RuntimeWatchdogSec`.

VMs with the `q35` machine type also have the chipset's own iTCO watchdog, which libvirt adds by
itself and gives the same action, `reset` when `watchdog` is not set. It also does nothing until
the guest starts it.

!!! warning
    Images that start the watchdog early in boot and feed it only once booted can reset in a
    loop when the boot takes longer than the watchdog's timeout. Cisco IOS images do this,
    especially under nested virtualization, so do not give them a `reset` watchdog.

##### container (object)

Settings only a container takes.

```toml
[nodes.container]
user = "root"
privileged = true
shm_size = 67108864
commands = ["sleep", "infinity"]
volumes = [
  { src = "/host/path", dst = "/container/path" },
]
platform = "bx"
```

| Key | Type | Description |
|---|---|---|
| `user` | string | The user the container runs as, in place of the image's |
| `privileged` | bool | Run the container in privileged mode |
| `shm_size` | int | Shared memory (`/dev/shm`) size in bytes |
| `commands` | list&lt;string&gt; | The container's command, in place of the image's |
| `volumes` | list&lt;object&gt; | Bind mounts of server paths into the container: `src`, the path on the Sherpa server, and `dst`, the path in the container |
| `platform` | string | The PTX router a `juniper_cevolved` node emulates, see below |

A privileged container, or one that can mount server paths, is root on the Sherpa server, so
only admins may set `privileged` or `volumes`; `up` and `redeploy` refuse a manifest from
another user that does.

Some models set their own command, user, privileges or mounts to start their software and mount
their ZTP config; see the model's page under Nodes.

`platform` is `bt` (PTX10001-36MR, 12 data interfaces) or `bx` (PTX10002-36QDD, up to 36).
Without it, the node is `bt`. Other models do not take `platform`. See
[Juniper cEvolved](nodes/juniper/juniper-cevolved.md#platforms).

##### unikernel (object)

Settings only a unikernel takes.

```toml
[nodes.unikernel]
cmdline = "/usr/bin/nginx"
```

| Key | Type | Description |
|---|---|---|
| `cmdline` | string | Kernel command line arguments, passed to QEMU via the libvirt `<cmdline>` XML element. Overrides any auto-injected command line |

`cmdline` applies only to unikernels using the `direct_kernel` boot mode.

##### Tuning a virtual machine

A virtual machine's performance settings are in its `cpu`, `numa`, `boot_disk` and `interfaces`
groups: how its CPU is presented, which host CPUs it runs on, which NUMA node holds its memory,
and how its disks and interfaces work.

```toml
[[nodes]]
name = "dev"
model = "ubuntu_linux"
memory = 49152

[nodes.cpu]
count = 14
mode = "host-passthrough"
topology = { sockets = 1, cores = 7, threads = 2 }
pinning = [9, 25, 10, 26, 11, 27, 12, 28, 13, 29, 14, 30, 15, 31]
emulator_pinning = [8, 24]

[nodes.numa]
node = 1
memory_mode = "preferred"

[nodes.boot_disk]
cache = "none"
io = "io_uring"
io_thread_cpus = [8, 24]

[nodes.interfaces]
queues = 4
```

Host CPUs and NUMA nodes are numbered from 0, as on the host (`lscpu`, `numactl -H`).

Rules for pinned host CPUs:

- `cpu.topology`, `cpu.pinning` and `interfaces.queues` need `cpu.count` to be set.
- **A CPU in `cpu.pinning` belongs to that node alone.** No other node can pin a vCPU to it,
  in any lab on the server, and no node can run its QEMU or I/O threads on it, the same
  node included.
- **`cpu.emulator_pinning` and `boot_disk.io_thread_cpus` may share CPUs** with each other and
  with the same settings on other nodes.
- **The checks run at `sherpa up` and `sherpa redeploy`.** Every CPU and the NUMA node must
  exist on the server.

The memory of a node with `numa.node` and `numa.memory_mode = "strict"` (or left out) must fit
on that NUMA node beside the other virtual machines held strictly there, or `sherpa up`,
`sherpa redeploy` and `sherpa resume` refuse it (see
[`[host_memory]`](configuration/sherpa.md#host_memory)). Virtual machines without `numa.node`
may still fill that node, and the guest held there cannot take memory elsewhere: when the node
runs out, the host's OOM killer stops a virtual machine. Leave room on the node, pin every
large virtual machine on the server, or use `numa.memory_mode = "preferred"`.

With `numa.memory_mode = "preferred"` the memory only counts against the whole server, not
against the NUMA node. When the node is full the guest takes memory from another node, which is
slower to reach, instead of being stopped.

Pinning keeps a virtual machine's threads on those CPUs. It does not reserve the CPUs: the
host can still run other work on them.

##### Upgrading manifests from flat keys

Releases up to 0.5.35 took these settings as flat keys of the node, and the virtual machine
tuning in a `[nodes.performance_tuning]` table. Sherpa now refuses those keys with an
`unknown field` error that names the key. Move each to its group:

| Old key | New key |
|---|---|
| `cpu_count` | `cpu.count` |
| `performance_tuning.cpu_mode` | `cpu.mode` |
| `performance_tuning.cpu_topology` | `cpu.topology` |
| `performance_tuning.cpu_pinning` | `cpu.pinning` |
| `performance_tuning.qemu_cpus` | `cpu.emulator_pinning` |
| `performance_tuning.numa_node` | `numa.node` |
| `performance_tuning.numa_memory_mode` | `numa.memory_mode` |
| `boot_disk_size` | `boot_disk.size` |
| `boot_disk_clone_method` | `boot_disk.clone_method` |
| `performance_tuning.disk_cache` | `boot_disk.cache` |
| `performance_tuning.disk_io` | `boot_disk.io` |
| `performance_tuning.disk_io_thread_cpus` | `boot_disk.io_thread_cpus` |
| `data_interface_count` | `interfaces.data_count` |
| `performance_tuning.interface_queues` | `interfaces.queues` |
| `ztp` | `ztp.method` |
| `ztp_config` | `ztp.config` |
| `ssh_authorized_keys` | `ssh.authorized_keys` |
| `ssh_authorized_key_files` | `ssh.authorized_key_files` |
| `ready_port` | `ready_check.port` |
| `skip_ready_check` | `ready_check.skip` |
| `watchdog` | `vm.watchdog` |
| `user` | `container.user` |
| `privileged` | `container.privileged` |
| `shm_size` | `container.shm_size` |
| `commands` | `container.commands` |
| `volumes` | `container.volumes` |
| `platform` | `container.platform` |
| `kernel_cmdline` | `unikernel.cmdline` |

`name`, `model`, `image`, `version`, `memory`, `environment_variables`, `text_files`,
`binary_files`, `systemd_units`, `startup_scripts`, `user_scripts` and `provisioners` are
unchanged. For example:

```toml
# Before
[[nodes]]
name = "dev01"
model = "ubuntu_linux"
cpu_count = 4
data_interface_count = 2
skip_ready_check = true

# After
[[nodes]]
name = "dev01"
model = "ubuntu_linux"

[nodes.cpu]
count = 4

[nodes.interfaces]
data_count = 2

[nodes.ready_check]
skip = true
```

`sherpa resume` of a lab created before the change uses the default readiness settings, because
the lab's saved manifest has the old keys.

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

Multiline strings and Unicode are supported, up to 1000 characters. Line breaks and tabs are
the only control characters allowed; `sherpa validate` and `sherpa up` refuse others.

The description is shown wherever the lab is: `sherpa inspect`, the web UI's labs list and lab
page, the admin labs page, and the API's lab details and lab list.

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
| `impairment` | object | no | Network impairment configuration |

#### Link Impairment

Apply network impairment to simulate real-world link conditions. The values apply to both
directions. To impair each direction differently, or to change it on a running lab, use
[`sherpa link impair`](command-reference.md#sherpa-link-impair).

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
| `delay` | int | One-way delay in milliseconds, up to `274877` (about 4.5 minutes) |
| `jitter` | int | Delay jitter in milliseconds, up to `274877` |
| `loss_percent` | float | Packet loss percentage (`0.0` - `100.0`) |
| `reorder_percent` | float | Packet reordering percentage (`0.0` - `100.0`). Reordered packets skip the delay, so set a `delay` too |
| `corrupt_percent` | float | Bit-flip corruption percentage (`0.0` - `100.0`) |

`sherpa validate` and `sherpa up` refuse a value outside these ranges, naming the link.

Every link is a P2P eBPF link. The `p2p` setting has been removed, and a manifest that still
sets it fails validation; see [the removed `p2p` setting](architecture/networking/modes/point-to-point.md#the-removed-p2p-setting).

### provision_current_user (bool)

Create an account for the lab owner on lab nodes, using the owner's Sherpa username and
registered SSH public keys: Linux, BSD and Windows VMs, and network devices. Defaults to `false`.

```toml
provision_current_user = true
```

See [Personal Accounts](architecture/personal-accounts.md) for the nodes it applies to and the
key types each network device takes. A node with a custom `ztp.config` gets no account.

### ready_timeout (int)

Global timeout in seconds for node readiness checks. Overrides the default timeout for all nodes in the lab.
It applies to `sherpa up`, `sherpa redeploy` and `sherpa resume`.

```toml
ready_timeout = 300
```

### provision_concurrency (int)

How many nodes the `sherpa` CLI runs [ssh provisioners](architecture/provisioners/ssh.md) on at
the same time. Defaults to `8`, and must be from `1` to `255`. Use `1` to provision one node at a
time. Only the CLI reads it: it is not sent to the server.

```toml
provision_concurrency = 4
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

Set the named variable in the client shell before running `sherpa up` and
`sherpa resume`. Store only the variable name in the manifest, never the key. The
key is required for creation and for each whole-lab resume, because `sherpa down`
logs the gateway out. Omitting the section
or setting `enabled = false` requires no credential and creates no gateway.

Enrollment requires server TLS and WSS with certificate validation enabled.
Route approval is separate from enrollment; pending approval produces a warning
without failing lab creation. See [Tailscale setup and route approval](architecture/networking/tailscale.md).

### talos_clusters (list&lt;talos_cluster_object&gt;)

Kubernetes clusters built from the lab's [Talos Linux](nodes/linux/talos-linux.md) nodes. Each
cluster lists its member nodes by name. Sherpa generates each cluster's secrets and machine
configs, bootstraps it, and writes `.sherpa/k8s/kubeconfig-<cluster>` and
`.sherpa/talos/talosconfig-<cluster>` in your working directory.

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
| `cni` | string | `flannel` (the default) or `cilium`. See [Cilium](nodes/linux/talos-linux.md#cilium) |
| `oidc` | string | A `keycloak_server` node whose `sherpa` realm users log in to the cluster. Optional. See [Keycloak login](nodes/linux/talos-linux.md#keycloak-login) |
| `vault` | string | A `hashicorp_vault` node, without `ztp.config`, the cluster's workloads read secrets from. Optional. See [Vault secrets](nodes/linux/talos-linux.md#vault-secrets) |

Members must be `talos_linux` nodes defined in [`nodes`](#nodes-listnode_object), and a node can
be listed only once across all clusters. A `talos_linux` node that is not listed is a standalone
Talos node.

Each cluster needs one or three controllers. Two are refused: etcd needs a majority of its
members to stay up, so two controllers survive no failure and are less available than one.
A lab can have several clusters; at most two of them can have three controllers, and at most
two can use Cilium.

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
