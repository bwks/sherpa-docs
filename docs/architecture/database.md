# Database

`sherpad` keeps its data in an embedded [Turso](https://github.com/tursodatabase/turso)
database, a Rust rewrite of SQLite that runs inside the `sherpad` process.

## Storage

| Item | Location |
| ---- | -------- |
| Database file | `/opt/sherpa/db/sherpa.sqlite` |
| Write-ahead log | `/opt/sherpa/db/sherpa.sqlite-wal`, next to the database file |
| Backups | `/opt/sherpa/db/backups/` |
| Database key | `/opt/sherpa/.secret/db.key` |

The database and its backups hold password hashes and every lab's definition, so `/opt/sherpa/db`
is readable only by the `sherpa` user and group, and `/opt/sherpa/db/backups` only by `sherpa`.
The install script, the update script and `sherpad` keep those modes.

### Lab definitions

The database records every lab's definition: each parameter of the manifest it was started
from, **as you wrote it**. `sherpa redeploy` replaces the redeployed node's.

**File contents and variable values are not stored.** Files and scripts are recorded by the path
and settings the manifest gives: `ztp.config`, `text_files` (`src`, `dst`, `user`, `group`,
`permissions`), `binary_files`, `systemd_units`, `startup_scripts`, `user_scripts`
and each provisioner's files. Environment variables are recorded as
written: `KEY=$VAR` keeps the name `$VAR`, never its value. The `sherpa` CLI still reads the
files and resolves the variables, and sends them with each `sherpa up` and `sherpa redeploy` to
build the node, but the server does not write them to its database.

A lab with no definition is used with the defaults: `sherpa resume` waits the default readiness
timeout, containers get their image's number of data interfaces, and it cannot be redeployed
from the web UI until `sherpa redeploy` records one.

### Database key

Passwords are stored encrypted (AES-256-GCM): each user's
[device password](device-password.md). The database refuses a device password that is
not encrypted. The key is in
`/opt/sherpa/.secret/db.key`, beside the JWT secret in a folder only `sherpa` can open (mode
`700`): 32 random bytes, readable only by `sherpa`, which `sherpad` creates
the first time it starts. The key is never in the database or its backups, so a database or a
backup copied off the server shows no password.

Keep the key with the database:

- **Back it up alongside the database, separately.** Keep a copy of the key wherever you keep
  database backups, but not in the same file or folder. A backup restored without its key, or
  with another one,
  does not start: see
  [Troubleshooting](../help/troubleshooting.md#sherpad-does-not-start-the-database-key-is-missing-or-does-not-match).
- **Do not delete or replace it.** `sherpad` never replaces a missing or damaged key for a
  database that has encrypted values; it refuses to start and names the file.

The file is in SQLite's format and is owned by the `sherpa` user. While `sherpad` runs, it holds
the file exclusively: other programs, including the `sqlite3` command, cannot open it. To look
inside the database, open a [backup](#backups), or stop `sherpad` first.

## Backups

An administrator takes a backup with [`sherpa server backup`](../command-reference.md#sherpa-server-backup).
The server writes a consistent copy of the database to
`/opt/sherpa/db/backups/sherpa-<time>.sqlite`, named after the UTC time, and prints its path and
size. The server stays up while it runs; changes wait until the copy is finished.

Backups stay on the server. Copy them elsewhere to keep them safe from a disk failure, and back
up the [database key](#database-key), `/opt/sherpa/.secret/db.key`, alongside them but
separately: not in `/opt/sherpa/db/backups`, and not in the same copy or archive, so that one
stolen copy is not both. A backup holds no copy of the key, and `sherpad` does not start on a
backup without its key. Everything else in a backup is as
readable as the database itself, including the [lab definitions](#lab-definitions).

To restore a backup:

1. Stop the server: `sudo systemctl stop sherpad`.
2. Keep the current database aside, for example by renaming `/opt/sherpa/db/sherpa.sqlite` and
   any `sherpa.sqlite-wal` and `sherpa.sqlite-shm` next to it.
3. Copy the backup to `/opt/sherpa/db/sherpa.sqlite`, owned by `sherpa`.
4. If the backup comes from another server, or from before the key was last replaced, copy the
   key backed up with it to `/opt/sherpa/.secret/db.key`, owned by `sherpa`, mode `600`.
5. Start the server: `sudo systemctl start sherpad`.

## Schema

Tables use SQLite's `STRICT` mode, so every column holds only its declared type. Ranges, such as
CPU counts and port numbers, are checked by `CHECK` constraints. Columns that hold one of a fixed
set of values, such as a node model, are checked against the values the running version of
Sherpa knows. A node state written by a newer version is read as `unknown`.

The database records its schema version. When `sherpad` starts, it brings an older database up to
date. It refuses to start on a database from a newer version of Sherpa, for example after a
downgrade; restore a backup taken before the upgrade instead.

### Tables

#### user

Stores user accounts and credentials.

| Field           | Type            | Description                     |
| --------------- | --------------- | ------------------------------- |
| `username`      | text            | Unique lower-case username, 3–32 chars |
| `password_hash` | text            | Argon2id password hash          |
| `is_admin`      | boolean         | Admin flag                      |
| `ssh_keys`      | list of text    | Public SSH keys                 |
| `created_at`    | time            | Account creation time           |
| `updated_at`    | time            | Last update time                |
| `device_password` | text, optional | The user's [device password](device-password.md), encrypted; none until set |
| `failed_logins` | number          | Failed logins since the last successful one; 3 in a row lock the account |
| `locked_at`     | time, optional  | When failed logins locked the account; none when it is not locked |

#### login_attempt

One row for each login attempt on an account that was not locked. Rows are kept; they are
deleted only with their user.

| Field          | Type    | Description                                           |
| -------------- | ------- | ----------------------------------------------------- |
| `user`         | user    | The account (cascade delete)                          |
| `attempted_at` | time    | When the attempt was made                             |
| `succeeded`    | boolean | Whether the login succeeded                           |
| `address`      | bytes   | The source address: 4 bytes for IPv4, 16 for IPv6. An IPv4 address sent as IPv6 (`::ffff:192.0.2.1`) is stored as IPv4 |

#### node_image

Stores imported VM, container, and unikernel image definitions with their default parameters.
The combination of `model`, `kind` and `version` is unique. An image holds the settings every
kind takes and only its own kind's: the database refuses a setting on an image of a kind that
does not take it, and an image without one its kind needs.

| Field                           | Kinds                     | Type    | Description                              |
| ------------------------------- | ------------------------- | ------- | ---------------------------------------- |
| `model`                         | all                       | text    | Node model identifier                    |
| `version`                       | all                       | text    | Image version                            |
| `kind`                          | all                       | text    | virtual_machine, container, or unikernel |
| `cpu_count`                     | all                       | number  | Default CPU count (1-255)                |
| `memory`                        | all                       | number  | Default RAM in MB (64-65535)             |
| `data_interface_count`          | all                       | number  | Number of data interfaces                |
| `management_interface`          | all                       | text    | Management interface name                |
| `reserved_interface_count`      | all                       | number  | Interfaces held back from links          |
| `default`                       | all                       | boolean | Default image flag                       |
| `os_variant`                    | VM                        | text    | Operating system variant                 |
| `cpu_architecture`, `cpu_model` | VM, unikernel             | text    | The CPU the guest sees                   |
| `vmx_enabled`                   | VM                        | boolean | Nested virtualisation                    |
| `machine_type`                  | VM, unikernel             | text    | QEMU machine type                        |
| `bios`, `hdd_bus`, `cdrom_bus`  | VM                        | text    | Firmware and disk buses                  |
| `cdrom`                         | VM, optional              | text    | CD-ROM shipped with the image            |
| `interface_type`                | VM, unikernel             | text    | Interface device                         |
| `interface_mtu`                 | VM, unikernel             | number  | Interface MTU (576-9600)                 |
| `ztp`                           | VM, container             | text    | ZTP setting: `disabled` or a method      |
| `repo`                          | container, optional       | text    | Docker repo the image runs from          |
| `boot_mode`                     | unikernel                 | text    | `direct_kernel` or `disk_boot`           |

#### lab

Stores lab topology instances. Each lab belongs to a user. Lab IDs are unique, a user's lab names
are unique, and no two labs share a network.

| Field                  | Type            | Description                     |
| ---------------------- | --------------- | ------------------------------- |
| `lab_id`               | text            | Unique 8-character lab ID       |
| `name`                 | text            | Lab name                        |
| `user`                 | user            | Owner (delete refused)          |
| `management_network`   | text            | IPv4 management network         |
| `gateway_ipv4`         | text            | IPv4 gateway address            |
| `description`          | text, optional  | The manifest's `description`    |
| `ready_timeout`, `provision_concurrency`, `tailscale_*` | | The manifest's lab-level settings |

#### node

Stores individual node instances within a lab. Node names and indexes are unique within a lab.

| Field       | Type                  | Description                           |
| ----------- | --------------------- | ------------------------------------- |
| `name`      | text                  | Node name                             |
| `index`     | number                | Node index (unique per lab)           |
| `image`     | node_image            | Image (delete refused)                |
| `lab`       | lab                   | Lab (cascade delete)                  |
| `mgmt_ipv4` | text, optional        | Management IPv4 address               |
| `mgmt_ipv6` | text, optional        | Management IPv6 address               |
| `mgmt_mac`  | text, optional        | Management MAC address                |
| `state`     | text                  | [Node state](../command-reference.md#node-states) |
| `ssh_host_key` | text, optional     | The SSH host key the node offered when it last became ready |
| `ssh_username` | text, optional     | The account the lab's SSH config logs in to the node with: the lab owner's on a node with a generated login, `admin` on Cisco FTDv, else empty and the owner's name is used |
| `version`, `manifest_memory`, `cpu_*`, `numa_*`, `boot_disk_*`, `interfaces_*`, `ztp_*`, `vm_*`, `container_*`, `unikernel_*`, ... | | The node's settings from the manifest |

#### manifest_*

The lists of a lab's definition, one table each: its links, bridges and Talos clusters, and each
node's CPU lists, SSH keys, commands, volumes, environment variables, files, scripts, systemd
units and provisioners. Each row belongs to a lab or a node, and is deleted with it.

#### talos_cluster_plan

What Sherpa works out for each Talos cluster when the lab is brought up, beside the cluster in
the lab's definition. Its members' addresses are their nodes' `mgmt_ipv4`.

| Field                 | Type           | Description                                        |
| --------------------- | -------------- | -------------------------------------------------- |
| `lab`, `cluster`      | lab, number    | The cluster in the lab's definition (cascade delete) |
| `endpoint`            | text           | Address of the cluster's Kubernetes API            |
| `vip`                 | text, optional | Shared address of a cluster with three controllers |
| `load_balancer_first`, `load_balancer_last` | text, optional | Load balancer addresses of a Cilium cluster |

#### link

Stores point-to-point connections between nodes.

| Field      | Type             | Description                        |
| ---------- | ---------------- | ---------------------------------- |
| `index`    | number           | Link index                         |
| `kind`     | text             | Link kind (`p2p`)                  |
| `node_a`   | node             | Source node (cascade delete)       |
| `node_b`   | node             | Destination node (cascade delete)  |
| `int_a`    | text             | Source interface                   |
| `int_b`    | text             | Destination interface              |
| `tap_a`    | text             | Host end of the source side        |
| `tap_b`    | text             | Host end of the destination side   |
| `a_to_b_*` | numbers          | Impairment from source to destination: delay, jitter, loss, reorder, corrupt |
| `b_to_a_*` | numbers          | Impairment from destination to source |
| `lab`      | lab              | Lab (cascade delete)               |

#### bridge and bridge_member

`bridge` stores shared bridge network segments, and `bridge_member` the node interfaces connected
to each, in order.

| Field          | Type        | Description                       |
| -------------- | ----------- | --------------------------------- |
| `index`        | number      | Bridge index, unique per lab      |
| `bridge_name`  | text        | Linux bridge name                 |
| `network_name` | text        | Network name                      |
| `lab`          | lab         | Lab (cascade delete)              |

| Member field | Type   | Description                         |
| ------------ | ------ | ----------------------------------- |
| `bridge`     | bridge | Bridge (cascade delete)             |
| `position`   | number | Order within the bridge             |
| `node`       | node   | Member node (cascade delete)        |
| `interface`  | text   | Member interface                    |

### Referential Integrity

The database enforces these rules itself:

- A **user** who owns **labs** cannot be deleted. Destroy their labs first; deleting only the records would leave the labs' VMs, containers and networks running.
- Deleting a **lab** deletes all its **nodes**, **links**, **bridges** and bridge memberships,
  and its definition.
- Deleting a **node** deletes its **links** and its bridge memberships.
- Deleting a **node_image** is refused while any **node** uses it.
- Deleting a **user** deletes their **login_attempt** rows.
- Changes that touch several records, such as creating a bridge with its members, either happen
  completely or not at all.

## Initialization

`sherpad init` creates the database file, applies the schema, and creates the built-in `admin`
account and a first user account. On every start, `sherpad` opens the file and brings the schema
up to date. If the `admin` account is missing, the server creates it when `SHERPA_ADMIN_PASSWORD`
is set, and otherwise refuses to start until you run `sherpad init`.

The schema protects the built-in `admin` account: it cannot be deleted, renamed or lose its admin
flag, even by a statement run directly against the database.
