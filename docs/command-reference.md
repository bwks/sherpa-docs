# Command Reference

## Global Flags

These flags are available on all commands.

| Flag | Description |
| ---- | ----------- |
| `--server-url` | Remote server URL for WebSocket RPC (env: `SHERPA_SERVER_URL`) |
| `--insecure` | Skip TLS certificate validation (development only) |

## Exit Status

A command exits with a non-zero status when any part of what it asked for failed, after
printing what did not work, so scripts can rely on it:

- `sherpa up`: the lab was only partly created.
- `sherpa down` and `sherpa resume`: a node did not stop or start.
- `sherpa redeploy`: the node was not redeployed.
- `sherpa provision`: a node was not provisioned.
- `sherpa link impair`: the impairment was not changed.
- `sherpa destroy` and `sherpa server clean`: a resource of the lab was not removed.
- `sherpa server image` commands: the import, pull, delete or default change failed.

## Authentication

### `sherpa login`

Login to the Sherpa server. The username and password come from `SHERPA_USER_NAME` and
`SHERPA_USER_PASSWORD` when they are set, otherwise you are prompted for them. Use the variables
for scripts; the password is never taken as a flag, so it stays out of the process list and shell
history.

### `sherpa logout`

Logout from the Sherpa server. Removes the stored authentication token.

### `sherpa whoami`

Show the current authentication status and user information. When your token is invalid or
has expired, it says so and exits with an error, so a script can run
`sherpa whoami || sherpa login`.

## Lab Lifecycle

Lab commands act on the lab of the current folder: the one `lab-info.toml` names, written by
`sherpa up` and `sherpa download`, or else the one `manifest.toml` describes. When both files
are present and name different labs, as after renaming the lab in `manifest.toml` or
downloading another lab into the folder, the commands refuse to run and name both labs.
Destroy the old lab, or remove `lab-info.toml`, before using the folder for the other one.

### `sherpa new`

Create a new example `manifest.toml` in the current directory.

| Flag | Description |
| ---- | ----------- |
| `--force`, `-f` | Overwrite manifest file if one exists |

The generated manifest has a random lab name and two linked Linux nodes:

```toml
name = "absolute-grubworm"
provision_current_user = false

[[nodes]]
name = "dev01"
model = "ubuntu_linux"

[[nodes]]
name = "dev02"
model = "fedora_linux"

[[links]]
src = "dev01::eth1"
dst = "dev02::eth1"
```

### `sherpa init`

Initialise a Sherpa client environment. Creates the `~/.sherpa` directory structure and default configuration.

| Flag | Description |
| ---- | ----------- |
| `--force`, `-f` | Overwrite config file if one exists |

### `sherpa up`

Build the lab environment. Reads `manifest.toml` from the current directory, sends it to the server, and deploys all nodes and links.

The server records where the lab was started from: your machine's hostname and the current
directory. `sherpa inspect` and the web UI's lab page show them as **Client Host** and
**Client Folder**, so you can find the folder of a lab later.

When `[tailscale]` is enabled, resolves the auth key from the client environment
variable named by `auth_key_env` and creates a gateway for the lab. Enrollment
requires WSS with certificate validation enabled. Pending route approval produces
a warning without failing creation. See the [Tailscale guide](architecture/networking/tailscale.md).

When the manifest declares [Talos clusters](manifest.md#talos_clusters-listtalos_cluster_object), `up` also
bootstraps each Kubernetes cluster, waits for its nodes to be Ready, and writes
`kubeconfig-<cluster>` and `talosconfig-<cluster>` to the current directory, readable only by
you. For a [Cilium](nodes/linux/talos-linux.md#cilium) cluster it also prints the Gateway and
Hubble UI addresses. A cluster that is not ready in time is reported as a warning. See
[Talos Linux](nodes/linux/talos-linux.md).

`up` writes the [lab CA](architecture/certificates.md) to `lab-ca.crt`; for each
[Vault](nodes/hashicorp/hashicorp-vault.md) node Sherpa initialised, its address, root token and
unseal key to `vault-<node>.toml`; and for each [Keycloak](nodes/keycloak/keycloak-server.md)
node, its `sherpa` realm's users and passwords to `keycloak-<node>.toml`. The credential files
are readable only by you.

#### Stopping a running command

`sherpa up`, `sherpa redeploy` and `sherpa resume` run on the server, which keeps them running
if the client disconnects. Pressing Ctrl-C asks whether to stop the operation on the server too:

```
⚠️ Interrupted. The lab creation is still running on the server.
   It stops at its next step and removes what it has created.
Stop the lab creation on the server too? [y/N]:
```

- **No** (the default): the command exits and the operation carries on. Check on it with
  `sherpa inspect`.
- **Yes**: the server stops the operation at its next step and the command waits until it has.
  A stopped `up` removes what it has created, as a failed one does. A stopped `redeploy` may
  leave the node half rebuilt; redeploy it again. A stopped `resume` stops waiting for nodes;
  nodes already started keep running.

`sherpa destroy` also stops any of these operations still running on the lab before removing
it.

### `sherpa down`

Stop all or a specific node in the lab.

Virtual machines are asked to shut down cleanly (through the QEMU guest agent when the guest
has one, otherwise the ACPI power button) and are powered off only if they are still running
after 60 seconds. Nodes in a [Talos cluster](manifest.md#talos_clusters-listtalos_cluster_object)
are shut down through the Talos API, workers before controllers. Unikernels and other Talos
nodes are powered off, and containers are paused. The result for each node says whether it
shut down or was powered off.

With Tailscale enabled, a full shutdown also logs the gateway out of the tailnet and
stops it. Using `--node` leaves the gateway alone.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target a specific node (omit for all nodes) |

### `sherpa resume`

Resume all or a specific stopped node in the lab. Ctrl-C asks whether to stop the resume on
the server too; see [stopping a running command](#stopping-a-running-command).

Like `sherpa up`, resume waits for each VM or unikernel it boots to become ready,
showing progress as it goes. It uses the lab's `ready_timeout`, and each node's
`skip_ready_check` and `ready_port`, from the manifest the lab was created with. A node
that is not ready within the timeout is reported, but resume still succeeds. Containers
and paused nodes do not wait, because they resume an already running guest.

Nodes that boot may offer a new SSH host key, which the server records. Resume then
downloads the lab files again, as `sherpa download --force` does, so `sherpa_known_hosts`
matches. See [Node Host Keys](architecture/ssh.md#node-host-keys).

With Tailscale enabled, a full resume enrolls the gateway again before resuming
nodes, as `sherpa down` logged it out. Run it in the lab folder with the variable
named by `auth_key_env` set, as for `sherpa up`; it needs WSS with certificate
validation. Using `--node` leaves the gateway alone and needs no key. See
[Tailscale](architecture/networking/tailscale.md#lab-lifecycle).

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target a specific node (omit for all nodes) |

### `sherpa redeploy`

Destroy and recreate a single node with fresh ZTP configuration. Ctrl-C asks whether to stop
the redeploy on the server too; see [stopping a running command](#stopping-a-running-command).

A worker in a [Talos cluster](manifest.md#talos_clusters-listtalos_cluster_object) rejoins with the cluster's saved
secrets. A cluster controller cannot be redeployed.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target node to redeploy (required) |

When the node has [provisioners](architecture/provisioners/overview.md), the CLI sends a container's
secret files with the redeploy, and runs `ssh` provisioners once the node is back.

### `sherpa provision`

Run node [provisioners](architecture/provisioners/overview.md) again from the lab's folder: send
containers' secret files to the server again, and copy files and run scripts over SSH. `sherpa
up` and `sherpa redeploy` run them already; use this after a failure, after changing a file, or
after a server reboot.

Nodes are provisioned at the same time, up to the manifest's
[`provision_concurrency`](manifest.md#provision_concurrency-int) (default 8). The CLI prints the
result for each node and exits with an error if any node was not provisioned.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target a specific node (omit for all nodes with provisioners) |

### `sherpa destroy`

Destroy the lab and all its resources, including its Tailscale gateway and
identity volume when present. A running gateway is logged out of the tailnet first. If either Tailscale removal fails, the server retains
database ownership and saved lab configuration so the owner or an admin can retry.
Other resources may already have been removed. See [cleanup recovery](architecture/networking/tailscale.md#recovery).

If `sherpa up`, `sherpa redeploy` or `sherpa resume` is still running on the lab, destroy
stops it first and waits for it to finish its current step, then removes the lab. This is
safe to use on a lab whose `up` was interrupted.

Once the lab is gone, destroy deletes the files `sherpa up` and `sherpa download` saved in
the lab folder: `sherpa_ssh_config`, `sherpa_ssh_key`, `sherpa_known_hosts`, `lab-ca.crt`,
`lab-info.toml`, each Vault node's `vault-<node>.toml`, each Keycloak node's
`keycloak-<node>.toml`, and each Talos cluster's `kubeconfig-<cluster>` and
`talosconfig-<cluster>`. Cluster names come from `manifest.toml`, so run destroy in the lab
folder. Other files, such as your own `kubeconfig-prod`, are left alone.

If the server cannot remove every resource, destroy prints what failed and exits with an
error. While the lab still exists on the server, the local files are kept, so nodes that are
still running stay reachable, and running `sherpa destroy` again removes them.

| Flag | Description |
| ---- | ----------- |
| `--yes`, `-y` | Skip confirmation prompt |

### `sherpa inspect`

Inspect the current lab environment. Shows node states, links, and lab details.
The lab details include **Client Host** and **Client Folder**, the machine and directory
`sherpa up` ran in. Labs started from the web UI or the API, and labs started before Sherpa
0.5.6, have neither.
For Tailscale-enabled labs, refreshes gateway state, Tailscale addresses, advertised
management routes, route approval, and warnings. This is the default command when
no subcommand is specified.

### `sherpa validate`

Validate the `manifest.toml` in the current directory without deploying.

## Node Access

### `sherpa ssh`

Open an interactive shell on a lab node over SSH, through the Sherpa server as the lab's
`sherpa_ssh_config` describes. Sherpa has its own SSH client, so no `ssh` program needs to be
installed.

```
sherpa ssh <name>
```

- The terminal type (`TERM`) and window size are passed to the node, and resizing the window
  resizes the remote terminal.
- Type `~.` at the start of a line to disconnect, for example from a node that stopped
  answering. Type `~~` to send a single `~`.
- `sherpa ssh` exits with the exit code of the node's shell, or 255 if the node did not
  report one. Windows nodes do not report it, so it is 0 there.
- The first time you connect to a Sherpa server, you are shown its host key fingerprint and
  asked to confirm it, as with OpenSSH. A confirmed key is added to `~/.ssh/known_hosts`. A
  server whose key has changed is refused.
- A node's host key is checked against the lab's `sherpa_known_hosts` file, which the server
  fills in as nodes become ready, so you are not asked about it. If the node's key has
  changed, as after a restart from the web UI, the new key is fetched from the server with a
  warning. See [Node Host Keys](architecture/ssh.md#node-host-keys).
- If your key has a passphrase, or the Sherpa server needs your password, you are asked for
  it, as with OpenSSH. A key loaded in your SSH agent needs no prompt. See
  [SSH](architecture/ssh.md).

### `sherpa console`

Connect to a device via serial console over Telnet.

```
sherpa console <name>
```

### `sherpa download`

Download lab files (SSH config, SSH key, lab-info, the nodes' host keys in
`sherpa_known_hosts`, and each cluster's `kubeconfig-<cluster>` and `talosconfig-<cluster>`)
for CLI use from a remote lab. Like `up`, it prints each Cilium cluster's Gateway and Hubble UI
addresses, and writes `lab-ca.crt`, each Vault node's `vault-<node>.toml` and each Keycloak
node's `keycloak-<node>.toml`.

```
sherpa download <lab_id>
```

| Flag | Description |
| ---- | ----------- |
| `--force`, `-f` | Overwrite existing lab files if they exist |

## Link Commands

### `sherpa link impair`

Change the impairment on a running P2P link. Run it in the lab's directory: the link is found in
`manifest.toml` by either of its ends.

```
sherpa link impair dev01::eth1 --delay 20 --loss 1.5
sherpa link impair dev01::eth1 --direction src-to-dst --delay 30
sherpa link impair dev01::eth1 --clear
```

| Flag | Description |
| ---- | ----------- |
| `--direction` | `src-to-dst` (traffic from the link's `src` to its `dst`), `dst-to-src`, or `both` (default) |
| `--delay` | One-way delay in milliseconds |
| `--jitter` | Delay jitter in milliseconds |
| `--loss` | Packet loss percentage (`0.0` - `100.0`) |
| `--reorder` | Packet reordering percentage (`0.0` - `100.0`). Reordered packets skip the delay, so set `--delay` too |
| `--corrupt` | Bit-flip corruption percentage (`0.0` - `100.0`) |
| `--clear` | Remove the impairment from the directions named |

Give at least one value, or `--clear`. The values replace the impairment on the directions
named, and a value left out is `0`; the other direction keeps its own. The change applies at
once and is kept across `sherpa down`/`sherpa resume` and redeploying either end. See
[Link Impairment](api-reference.md#link-impairment) for the API.

## Image Commands

Client-side image queries. These commands require authentication but not admin privileges.

### `sherpa image show`

Show detailed information about an image.

```
sherpa image show <model>
```

| Flag | Description |
| ---- | ----------- |
| `--version` | Show a specific version (defaults to the default version) |

### `sherpa image list`

List available images.

```
sherpa image list [model]
```

| Flag | Description |
| ---- | ----------- |
| `--container` | List container images only |
| `--unikernel` | List unikernel images only |
| `--virtual-machine` | List virtual machine images only |

Give at most one of `--container`, `--unikernel` and `--virtual-machine`; with none, every
kind is listed.

## Certificate Commands

Manage trusted server certificates using the Trust-On-First-Use (TOFU) system.

`cert show`, `cert trust` and `cert delete` take the server as a host (`10.100.58.10`), a
`host:port` (`10.100.58.10:3030`) or a `ws://` or `wss://` URL (`wss://10.100.58.10:3030/ws`).
A host without a port uses the Sherpa server's port, `3030`. Other URLs, such as `https://`
ones, are refused.

### `sherpa cert list`

List all trusted certificates.

### `sherpa cert show`

Show detailed certificate information for a server.

```
sherpa cert show <server_url>
```

### `sherpa cert trust`

Trust a certificate without connecting to the server.

```
sherpa cert trust <server_url>
```

### `sherpa cert delete`

Delete a trusted certificate.

```
sherpa cert delete <server_url>
```

## Server Commands

Server administration commands. Use `sherpa server --verbose` for debug logging and `sherpa server --output json` for JSON output.
Progress lines, such as those of an image import or pull, go to stderr, so with
`--output json` stdout holds only the JSON.

### `sherpa server status`

Check if the Sherpa server is reachable.

### `sherpa server clean`

Force clean all resources for a lab without requiring lab ownership. Admin only.
Tailscale gateway and identity-volume deletion still verify resource ownership
labels. If either removal fails, lab ownership and saved configuration are retained
for a cleanup retry.

```
sherpa server clean <lab_id>
```

### `sherpa server backup`

Back up the server's database while the server keeps running. Admin only. The server writes a
consistent copy to `/opt/sherpa/db/backups/sherpa-<time>.sqlite`, named after the UTC time, and
prints its path and size. The backup stays on the server. See
[Database backups](architecture/database.md#backups) for restoring one.

```
sherpa server backup
```

## Server User Commands

User management commands. Most require admin privileges.

### `sherpa server user create`

Create a new user account. Admin only.

```
sherpa server user create <username>
```

| Flag | Description |
| ---- | ----------- |
| `--admin` | Make the user an administrator |
| `--ssh-key` | SSH public keys (can be specified multiple times) |

Usernames are also your login name on lab nodes, so they follow Linux login name rules. A
username must:

- be 3–32 characters long
- start with a letter or underscore
- contain only letters, digits, underscores and hyphens
- not be a reserved name

Usernames are not case-sensitive. They are saved in lower case, so `Brad` is saved as `brad`,
and you can log in as either.

You are asked for the new user's password twice, and it cannot be empty. It is always typed:
`SHERPA_USER_PASSWORD` is not used, as it holds your own password for `sherpa login`.

Reserved names include `admin`, `root` and `sherpa`, system accounts such as `daemon` and
`nobody`, names starting with `systemd-`, and the default users of common images and network
devices, such as `ubuntu`, `core`, `ec2-user`, `cisco` and `cumulus`.

### `sherpa server user list`

List all user accounts. Admin only.

### `sherpa server user delete`

Delete a user account. Admin only.

The server refuses to delete:

- your own account;
- the built-in `admin` account;
- the last admin account;
- a user who owns labs. The error lists the labs. Destroy them first (admins can destroy
  any lab), then delete the user.

```
sherpa server user delete <username>
```

| Flag | Description |
| ---- | ----------- |
| `--force` | Skip confirmation prompt |

### `sherpa server user passwd`

Change a user's password.

```
sherpa server user passwd [username]
```

If no username is provided, changes the current user's password. You are asked for the new
password twice, and it cannot be empty; `SHERPA_USER_PASSWORD` is not used.

### `sherpa server user info`

Show detailed user information.

```
sherpa server user info [username]
```

If no username is provided, shows the current user's information.

### `sherpa server user ssh-key`

Manage SSH public keys. You need at least one registered key to start labs; see
[SSH Keys](architecture/ssh-keys.md). Each command acts on your own account. Admins can act on
any user with `--user`.

```
sherpa server user ssh-key list [--user <username>]
sherpa server user ssh-key add <key or .pub file> [--user <username>]
sherpa server user ssh-key remove <key, .pub file or SHA256 fingerprint> [--user <username>]
```

| Flag | Description |
| ---- | ----------- |
| `--user` | User whose keys to manage (defaults to the logged-in user) |

`list` shows each key's type, `SHA256:` fingerprint and comment. Adding a key that is already
registered, even with a different comment, is refused.

## Server Image Commands

Image management commands. All require admin privileges.

### `sherpa server image show`

Show detailed information about an image.

```
sherpa server image show <model>
```

| Flag | Description |
| ---- | ----------- |
| `--version` | Show a specific version (defaults to the default version) |

### `sherpa server image list`

List all images.

```
sherpa server image list [model]
```

| Flag | Description |
| ---- | ----------- |
| `--container` | List container images only |
| `--unikernel` | List unikernel images only |
| `--virtual-machine` | List virtual machine images only |

Give at most one of `--container`, `--unikernel` and `--virtual-machine`; with none, every
kind is listed.

### `sherpa server image scan`

Scan the images directory for on-disk images and import them to the database.

| Flag | Description |
| ---- | ----------- |
| `--container` | Scan container images |
| `--unikernel` | Scan unikernel images |
| `--virtual-machine` | Scan virtual machine images |
| `--dry-run` | Show what would be imported without making changes |

Give at most one of `--container`, `--unikernel` and `--virtual-machine`; with none, every
kind is scanned.

### `sherpa server image import`

Import a disk image file for a VM or unikernel model.

```
sherpa server image import --src <path> --version <version> --model <model>
```

| Flag | Description |
| ---- | ----------- |
| `--src`, `-s` | Source path of the disk image (required) |
| `--version`, `-v` | Version of the device model (required) |
| `--model`, `-m` | Model of the device (required) |
| `--default` | Set this image as the default version |

### `sherpa server image pull`

Pull a container image from an OCI registry or download a VM image from a URL.

```
sherpa server image pull --model <model>
```

| Flag | Description |
| ---- | ----------- |
| `--model`, `-m` | Model of the device image to pull (required) |
| `--version`, `-v` | Version of the image |
| `--repo`, `-r` | Full container image reference with a tag (e.g., `registry.io/account/image:version` or `localhost:5000/image:1`); digests (`@sha256:...`) are not supported |
| `--url`, `-u` | VM image download URL |
| `--default` | Set this image as the default version |

### `sherpa server image delete`

Delete an imported image from disk and the database.

```
sherpa server image delete --model <model> --version <version>
```

| Flag | Description |
| ---- | ----------- |
| `--model`, `-m` | Model of the device image to delete (required) |
| `--version`, `-v` | Version of the device image to delete (required) |

### `sherpa server image set-default`

Set the default version for an image model.

```
sherpa server image set-default --model <model> --version <version>
```

| Flag | Description |
| ---- | ----------- |
| `--model`, `-m` | Model of the device image (required) |
| `--version`, `-v` | Version to set as default (required) |

## Server Daemon

`sherpad` runs on the server. Besides `start`, `stop`, `restart`, `status`, `logs` and `doctor`,
it has two setup commands.

### `sherpad init`

Initialize the server: directories, `sherpa.toml`, SSH keys, libvirt network and storage pool,
the database, the built-in `admin` account and a first user account. See the
[Quickstart](quickstart.md) for the accounts and unattended use.

| Flag | Description |
| ---- | ----------- |
| `--force` | Overwrite an existing config and SSH keys |
| `--server-ipv4` | Server listen IPv4 address, default `0.0.0.0` (env: `SHERPA_SERVER_IPV4`) |
| `--server-ipv6` | Server listen IPv6 address, if any (env: `SHERPA_SERVER_IPV6`) |
| `--ws-port` | Server listen port, default `3030` (env: `SHERPA_SERVER_WS_PORT`) |
| `--http-port` | HTTP certificate endpoint port, default `3031` (env: `SHERPA_SERVER_HTTP_PORT`) |

Values come from the flags or the environment variables only. From 0.5.1, `sherpad init` no
longer reads `/opt/sherpa/env/sherpa.env`: the install script prints the `sherpad init` command
with the address and ports you gave it. Since 0.5.0 there are no database flags: the database is
a file `sherpad` manages itself.

### `sherpad migrate-db`

Move the data of a server older than 0.5.0 from its SurrealDB container into the embedded
database. Only releases 0.5.0 to 0.5.12 have it. The update script runs it for you; see
[Updating to 0.5.0](install-update/update/sherpa.md#updating-to-050). To run it by hand, see
[Moving the data by hand](install-update/update/sherpa.md#moving-the-data-by-hand).

| Flag | Description |
| ---- | ----------- |
| `--db-pass` | SurrealDB password, required (env: `SHERPA_DB_PASSWORD`) |
| `--db-port` | SurrealDB port, default `8000` (env: `SHERPA_DB_PORT`) |
