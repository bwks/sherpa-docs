# Database

Sherpa uses [SurrealDB](https://surrealdb.com/) as its database.

The `sherpad` server connects to a SurrealDB instance over WebSocket on startup. The database schema is applied automatically each time the server starts and is idempotent, making it safe to run repeatedly.

## Connection

| Property  | Value       |
| --------- | ----------- |
| Server    | localhost   |
| Port      | 8000        |
| Namespace | sherpa      |
| Database  | sherpa      |
| User      | sherpa      |
| Protocol  | WebSocket   |

## Configuration

Database credentials are managed via environment variables, not `sherpa.toml`.

| Variable               | Required | Description                                      |
| ---------------------- | -------- | ------------------------------------------------ |
| `SHERPA_DB_PASSWORD`   | Yes      | Database root password                           |
| `SHERPA_DB_PORT`       | No       | Database port (default: `8000`)                  |
| `SHERPA_ADMIN_PASSWORD`| No       | Seeds an `admin` user on startup if set          |

## Storage

SurrealDB uses the [RocksDB](https://rocksdb.org/) storage engine for persistent, file-based storage. The database file is located at `/opt/sherpa/db/sherpa.db` on the host and is mounted into the SurrealDB container at `/data/sherpa.db`. Data persists across container and host restarts.

## Schema

The database uses a `SCHEMAFULL` design where all tables, fields, and constraints are strictly defined. Field values are validated at the database level using constraints generated from the application code.

### Tables

The schema consists of 6 tables applied in dependency order.

#### user

Stores user accounts and credentials.

| Field           | Type            | Description                     |
| --------------- | --------------- | ------------------------------- |
| `username`      | string          | Unique username (min 3 chars)   |
| `password_hash` | string          | Argon2id password hash          |
| `is_admin`      | bool            | Admin flag (default: false)     |
| `ssh_keys`      | array\<string\> | Public SSH keys                 |
| `created_at`    | datetime        | Account creation time           |
| `updated_at`    | datetime        | Last update time                |

#### node_image

Stores imported VM, container, and unikernel image definitions with their default parameters.

| Field                           | Type           | Description                              |
| ------------------------------- | -------------- | ---------------------------------------- |
| `model`                         | string         | Node model identifier                    |
| `version`                       | string         | Image version                            |
| `kind`                          | string         | virtual_machine, container, or unikernel |
| `os_variant`                    | string         | Operating system variant                 |
| `cpu_count`                     | number         | Default CPU count (1-255)                |
| `memory`                        | number         | Default RAM in MB (64-65535)             |
| `data_interface_count`          | number         | Number of data interfaces                |
| `interface_prefix`              | string         | Interface naming prefix                  |
| `interface_type`                | string         | Interface driver type                    |
| `management_interface`          | string         | Management interface name                |
| `dedicated_management_interface`| bool           | Dedicated management interface flag      |
| `ztp_method`                    | string         | Zero touch provisioning method           |
| `default`                       | bool           | Default image flag                       |

#### lab

Stores lab topology instances. Each lab belongs to a user.

| Field                  | Type            | Description                     |
| ---------------------- | --------------- | ------------------------------- |
| `lab_id`               | string          | Unique 8-character lab ID       |
| `name`                 | string          | Lab name                        |
| `user`                 | record\<user\>  | Owner (cascade delete)          |
| `management_network`   | string          | IPv4 management network         |
| `gateway_ipv4`         | string          | IPv4 gateway address            |
| `loopback_network`     | string          | IPv4 loopback network           |

#### node

Stores individual node instances within a lab.

| Field       | Type                  | Description                           |
| ----------- | --------------------- | ------------------------------------- |
| `name`      | string                | Node name                             |
| `index`     | number                | Node index (unique per lab)           |
| `image`     | record\<node_image\>  | Image reference (reject delete)       |
| `lab`       | record\<lab\>         | Lab reference (cascade delete)        |
| `mgmt_ipv4` | option\<string\>      | Management IPv4 address               |
| `mgmt_ipv6` | option\<string\>      | Management IPv6 address               |
| `mgmt_mac`  | option\<string\>      | Management MAC address                |
| `state`     | string                | Node state (running, stopped, etc.)   |

#### link

Stores point-to-point connections between nodes.

| Field      | Type             | Description                        |
| ---------- | ---------------- | ---------------------------------- |
| `index`    | number           | Link index                         |
| `kind`     | string           | Bridge kind (p2p_bridge, etc.)     |
| `node_a`   | record\<node\>   | Source node (cascade delete)       |
| `node_b`   | record\<node\>   | Destination node (cascade delete)  |
| `int_a`    | string           | Source interface                    |
| `int_b`    | string           | Destination interface              |
| `lab`      | record\<lab\>    | Lab reference (cascade delete)     |

#### bridge

Stores shared bridge network segments.

| Field          | Type                    | Description                       |
| -------------- | ----------------------- | --------------------------------- |
| `index`        | number                  | Bridge index                      |
| `bridge_name`  | string                  | Linux bridge name                 |
| `network_name` | string                  | Network name                      |
| `lab`          | record\<lab\>           | Lab reference (cascade delete)    |
| `nodes`        | array\<record\<node\>\> | Connected nodes (unset on delete) |

### Referential Integrity

- Deleting a **user** cascades to delete all their **labs**.
- Deleting a **lab** cascades to delete all its **nodes**, **links**, and **bridges**.
- Deleting a **node** cascades to delete its **links** and unsets references in **bridges**.
- Deleting a **node_image** is rejected if any **nodes** reference it.

## Initialization

The database is initialized during `sherpa init` which connects to SurrealDB, applies the schema, and creates an initial admin user. On subsequent server starts, the schema is re-applied idempotently and an admin user is optionally seeded if `SHERPA_ADMIN_PASSWORD` is set.
