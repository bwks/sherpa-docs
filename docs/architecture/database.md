# Database

Since version 0.5.0, `sherpad` keeps its data in an embedded [Turso](https://github.com/tursodatabase/turso)
database, a Rust rewrite of SQLite that runs inside the `sherpad` process. There is no separate
database server, container, port or password.

Servers older than 0.5.0 used a SurrealDB container. They must update to 0.5.12 first, which
moves their data across; see [Updating to 0.5.0](../install-update/update/sherpa.md#updating-to-050).

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
`permissions`), `binary_files`, `systemd_units`, `startup_scripts`, `user_scripts`,
`ssh.authorized_key_files` and each provisioner's files. Environment variables are recorded as
written: `KEY=$VAR` keeps the name `$VAR`, never its value. The `sherpa` CLI still reads the
files and resolves the variables, and sends them with each `sherpa up` and `sherpa redeploy` to
build the node, but the server does not write them to its database.

Labs started before this was recorded get theirs from their saved manifest the first time
`sherpad` starts after the update. That saved manifest was resolved, so the import keeps only
what it holds as written: `ztp.config` and `environment_variables` are left out, and stored again
the next time you redeploy the node from your manifest. A lab whose saved manifest cannot be read
is logged and keeps none. The saved manifests are then deleted, `manifest.toml` and
`manifest.json` in each lab's directory and nothing else; the server no longer writes them, and
reads the lab's manifest only from its definition. A lab with no definition is used with the
defaults: `sherpa resume` waits the default readiness timeout, containers get their image's
number of data interfaces, and it cannot be redeployed from the web UI. The nodes of an imported
lab cannot be redeployed from the web UI either, until each has been redeployed once with
`sherpa redeploy`, which records its ZTP config and environment variables as written. A CLI older than the server sends only resolved values, so a lab it
starts has no `ztp.config`, environment variables or provisioners recorded.

### Database key

Passwords are stored encrypted (AES-256-GCM): an image's ZTP password, and `ztp_server.password`
from a lab's manifest. The key is in
`/opt/sherpa/.secret/db.key`, beside the JWT secret in a folder only `sherpa` can open (mode
`700`): 32 random bytes, readable only by `sherpa`, which `sherpad` creates
the first time it starts. The key is never in the database or its backups, so a database or a
backup copied off the server shows no password. Image passwords stored as plain text by
earlier releases are encrypted the first time `sherpad` starts after the update. The web UI and
the API never show an image's password: they say whether it is set, and the image editor takes
a new one, keeps the current one when the field is left blank, or removes it.

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

#### node_image

Stores imported VM, container, and unikernel image definitions with their default parameters.
The combination of `model`, `kind` and `version` is unique.

| Field                           | Type           | Description                              |
| ------------------------------- | -------------- | ---------------------------------------- |
| `model`                         | text           | Node model identifier                    |
| `version`                       | text           | Image version                            |
| `kind`                          | text           | virtual_machine, container, or unikernel |
| `os_variant`                    | text           | Operating system variant                 |
| `cpu_count`                     | number         | Default CPU count (1-255)                |
| `memory`                        | number         | Default RAM in MB (64-65535)             |
| `data_interface_count`          | number         | Number of data interfaces                |
| `interface_prefix`              | text           | Interface naming prefix                  |
| `interface_type`                | text           | Interface driver type                    |
| `management_interface`          | text           | Management interface name                |
| `ztp`                           | text           | ZTP setting: `disabled` or a method      |
| `ztp_password`                  | text, optional | ZTP password, encrypted                  |
| `default`                       | boolean        | Default image flag                       |

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
| `loopback_network`     | text            | IPv4 loopback network           |
| `description`          | text, optional  | The manifest's `description`    |
| `ready_timeout`, `provision_current_user`, `provision_concurrency`, `tailscale_*`, `ztp_server_*` | | The manifest's lab-level settings; `ztp_server_password` is encrypted |

#### node

Stores individual node instances within a lab. Node names and indexes are unique within a lab,
and VNC ports across all labs.

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
| `version`, `manifest_memory`, `cpu_*`, `numa_*`, `boot_disk_*`, `interfaces_*`, `ztp_*`, `vm_*`, `container_*`, `unikernel_*`, ... | | The node's settings from the manifest |

#### manifest_*

The lists of a lab's definition, one table each: its links, bridges and Talos clusters, and each
node's CPU lists, SSH keys, commands, volumes, environment variables, files, scripts, systemd
units and provisioners. Each row belongs to a lab or a node, and is deleted with it.

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
- Changes that touch several records, such as creating a bridge with its members, either happen
  completely or not at all.

## Initialization

`sherpad init` creates the database file, applies the schema, and creates the built-in `admin`
account and a first user account. On every start, `sherpad` opens the file and brings the schema
up to date. If the `admin` account is missing, the server creates it when `SHERPA_ADMIN_PASSWORD`
is set, and otherwise refuses to start until you run `sherpad init`.

The schema protects the built-in `admin` account: it cannot be deleted, renamed or lose its admin
flag, even by a statement run directly against the database.
