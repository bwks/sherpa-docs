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

- `sherpa up`: the lab was not created, or was only partly created: a container exited, or a
  Kubernetes cluster, Vault or Keycloak did not come up. A partly created lab is kept; use it as
  it is, or destroy it. A node that is only slow to become ready is a warning.
- `sherpa down` and `sherpa resume`: a node did not stop or start.
- `sherpa redeploy`: the node was not redeployed.
- `sherpa provision`: a node was not provisioned.
- `sherpa link impair`: the impairment was not changed.
- `sherpa destroy` and `sherpa server clean`: a resource of the lab was not removed. The lab is
  kept, `destroy failed`, so run the command again once the cause is fixed.
- `sherpa server image` commands: the import, pull, delete or default change failed.

## Authentication

### `sherpa login`

Login to the Sherpa server. The username and password come from `SHERPA_USER_NAME` and
`SHERPA_USER_PASSWORD` when they are set, otherwise you are prompted for them. Use the variables
for scripts; the password is never taken as a flag, so it stays out of the process list and shell
history.

### `sherpa logout`

Logout from the Sherpa server. It ends the session on the server, so the token stops working
everywhere, including any copy of it, then removes the stored token. Your other sessions, such as
a web UI login or a login on another machine, are not affected.

If the server cannot be reached, the stored token is still removed, and a warning says the
session could not be ended on the server: the token stays valid until it expires or your password
is changed.

### `sherpa whoami`

Show the current authentication status and user information. When your token is invalid or
has expired, it says so and exits with an error, so a script can run
`sherpa whoami || sherpa login`.

## Lab Lifecycle

Lab commands act on the lab of the current folder: the one `.sherpa/lab-info.toml` names,
written by
`sherpa up` and `sherpa download`, or else the one `manifest.toml` describes. When both files
are present and name different labs, as after renaming the lab in `manifest.toml` or
downloading another lab into the folder, the commands refuse to run and name both labs.
Destroy the old lab, or remove `.sherpa/lab-info.toml`, before using the folder for the other one.

Every file Sherpa generates in the lab folder goes in a `.sherpa/` folder next to `manifest.toml`.
`.sherpa/` and the folders in it are readable only by you, and so are the secret files. A lab
folder from a client before 0.5.15, with these files loose in the folder, keeps working: each command
that uses the lab folder first moves the files Sherpa generated into `.sherpa/`, rewrites the
paths in the SSH config, and points the `~/.ssh/sherpa_lab_hosts` include at
`.sherpa/ssh/config`. It prints `Moved N lab files into .sherpa` when it does. A `.sherpa` that
is a symlink is refused.

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

The lab is reserved before anything is created: a second `sherpa up` of a lab that exists, or
that another `up` is creating, is refused at once with "Lab already exists", and does not touch
the existing lab. Destroy it first to start it again.

A container whose process exits right after it starts is reported as a failed node, and the
rest of the lab is kept: see `docker logs <node>-<lab_id>` on the server for why it exited.
`sherpa up` then exits with an error, saying the lab was only partly created.

The server refuses the lab before creating anything when its virtual machines and unikernels
do not fit in the server's memory, or on the NUMA node a node is held on strictly. The error
names the numbers that fell short. See [`[host_memory]`](configuration/sherpa.md#host_memory).

When `[tailscale]` is enabled, resolves the auth key from the client environment
variable named by `auth_key_env` and creates a gateway for the lab. Enrollment
requires WSS with certificate validation enabled. Pending route approval produces
a warning without failing creation. See the [Tailscale guide](architecture/networking/tailscale.md).

When the manifest declares [Talos clusters](manifest.md#talos_clusters-listtalos_cluster_object), `up` also
bootstraps each Kubernetes cluster, waits for its nodes to be Ready, and writes
`.sherpa/k8s/kubeconfig-<cluster>` and `.sherpa/talos/talosconfig-<cluster>` in the current
directory, readable only by you. For a [Cilium](nodes/linux/talos-linux.md#cilium) cluster it
also prints the Gateway and
Hubble UI addresses. A cluster that is not ready in time is reported, and `sherpa up` exits with
an error, as nothing bootstraps it again; the rest of the lab is kept. See
[Talos Linux](nodes/linux/talos-linux.md).

`up` writes the [lab CA](architecture/certificates.md) to `.sherpa/ca/lab-ca.crt`; for each
[Vault](nodes/hashicorp/hashicorp-vault.md) node Sherpa initialised, its address, root token and
unseal key to `.sherpa/vault/vault-<node>.toml`; and for each
[Keycloak](nodes/keycloak/keycloak-server.md) node, its `sherpa` realm's users and passwords to
`.sherpa/keycloak/keycloak-<node>.toml`. The credential files
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
  A stopped `up` removes what it has created, as a failed one does. If that removal leaves
  something behind, the lab is kept, `destroy failed`; run `sherpa destroy`. A stopped `redeploy` may
  leave the node half rebuilt, marked `failed`; redeploy it again. A stopped `resume` stops waiting for nodes;
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
shut down or was powered off. A node that is already stopped or paused is reported as such, so
running `sherpa down` twice is not an error. A node that is `building` or `missing` (see
[node states](#node-states)) is not touched, and its result says why. A lab that is not
`ready` (see [lab phases](#lab-phases)) is refused.

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
and paused nodes do not wait, because they resume an already running guest. A paused
container is unpaused, a stopped one is started, and a running node is left as it is.
A booted node is `starting` until it is ready, then `running`; one that is not ready in time
stays `starting` until the server sees it answer.

Resume refuses, with a reason in the node's result, a node that is `building` or `missing`, a
virtual machine that crashed, a container that is dead, and one that is between states, such as
shutting down or restarting. A crashed, dead or missing node needs `sherpa redeploy`. A lab that
is not `ready` (see [lab phases](#lab-phases)) is refused.

Before starting any node, resume checks that the stopped virtual machines and unikernels fit
in the server's memory, as `sherpa up` does, and refuses the whole resume if they do not.

Nodes that boot may offer a new SSH host key, which the server records. Resume then
downloads the lab files again, as `sherpa download --force` does, so `.sherpa/ssh/known_hosts`
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

The node's memory must still fit on the server, as for `sherpa up`; the node being replaced
does not count against itself. A refused redeploy leaves the node as it was. A node that is
`building` cannot be redeployed until that finishes; a `missing` or `failed` node can. A lab
that is not `ready` (see [lab phases](#lab-phases)) is refused.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target node to redeploy (required) |

When the node has [provisioners](architecture/provisioners/overview.md), the CLI sends a container's
secret files with the redeploy, and runs `ssh` provisioners once the node is back.

The server checks the manifest, the node's image and the server's resources before it destroys
the node, so a refused redeploy leaves the node running as it was. A redeploy that fails once the
node is destroyed marks it `failed` in `sherpa inspect`; fix the cause and redeploy it again.
While it is rebuilt the node is `building`, then `starting`, and `running` once ready. A
container that runs Vault or Keycloak is `running` only once they are restored.

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

Once the lab is gone, destroy removes the lab's include from `~/.ssh/sherpa_lab_hosts` and
deletes the `.sherpa/` folder in the lab folder, with everything `sherpa up` and
`sherpa download` saved in it. It does not need `manifest.toml`. Other files in the lab folder,
such as your own `kubeconfig-prod` or `manifest.toml`, are left alone. A `.sherpa` that is a
symlink is not deleted.

If a lab folder from a Sherpa before 0.5.15 cannot be moved into `.sherpa` (every other command stops
on this), destroy prints a warning with the error and carries on. It still removes the include
of either the old `sherpa_ssh_config` or the new `.sherpa/ssh/config`, deletes `.sherpa/`, and
deletes the loose files the older Sherpa generated, such as `sherpa_ssh_key`, `lab-info.toml`
and `vault-<node>.toml`, by their exact names.

A destroy that waited behind another destroy of the same lab, and finds it gone, succeeds.

If the server cannot remove every resource, destroy prints what failed and exits with an
error, and the lab is `destroy failed` (see [lab phases](#lab-phases)). While the lab still exists on the server, the local files are kept, so nodes that are
still running stay reachable, and running `sherpa destroy` again removes them.

| Flag | Description |
| ---- | ----------- |
| `--yes`, `-y` | Skip confirmation prompt |

### `sherpa inspect`

Inspect the current lab environment. Shows [node states](#node-states), links, and lab details.
The lab details include the manifest's **Description**, and **Client Host** and
**Client Folder**, the machine and directory `sherpa up` ran in. Labs started from the web UI or the API, and labs started before Sherpa
0.5.6, have neither.
For Tailscale-enabled labs, refreshes gateway state, Tailscale addresses, advertised
management routes, route approval, and warnings. This is the default command when
no subcommand is specified.

#### Node states

| State | Meaning |
| ----- | ------- |
| `building` | `sherpa up` or `sherpa redeploy` is creating the node. Nothing else can stop, start or redeploy it until that finishes. |
| `starting` | The node is started but not ready yet: its ready check has not passed. The server's [scanner](configuration/sherpa.md#scanner) keeps checking, and records it `running` once it answers. |
| `running` | The node is ready: its ready check passed, or it has `skip_ready_check`. |
| `stopped` | The node is shut down or paused, by `sherpa down` or outside Sherpa. |
| `failed` | An operation on the node failed, such as a redeploy or a container that exited during `sherpa up`, or its virtual machine crashed or its container died. It stays `failed` until you stop, resume or redeploy it. |
| `missing` | The node's virtual machine or container no longer exists, for example because it was removed outside Sherpa. Redeploy it. |
| `unknown` | A state this version does not know, such as one written by a newer server. |

A lab's status follows its nodes: `running` or `stopped` when all of them are, `failed` when
any is `failed` or `missing`, `starting` when any is `building` or `starting`, otherwise
`partial`.

#### Lab phases

Besides its status, a lab has a phase: which operation, if any, owns it. While a lab is not
`ready`, the web UI shows its phase instead of its status and offers only Destroy, and
`sherpa inspect` and `sherpa destroy` print what to do. `sherpa down`, `sherpa resume` and
`sherpa redeploy` refuse a lab that is not `ready`.

| Phase | Meaning |
| ----- | ------- |
| `creating` | `sherpa up` is building the lab. Wait for it, or destroy the lab, which stops it. |
| `ready` | `sherpa up` finished. The lab's status says how its nodes are. |
| `destroying` | A destroy or clean is removing the lab. |
| `destroy failed` | A destroy, a clean, or the cleanup of a failed `sherpa up` left something behind. Run `sherpa destroy` again once the cause is fixed. |
| `interrupted` | The server stopped while `sherpa up` was building the lab. Destroy it, and run `sherpa up` again. |
| `unknown` | A phase this version does not know, such as one written by a newer server. Only destroy is offered. |

When the server starts, a lab it was creating becomes `interrupted`, a lab it was destroying
becomes `destroy failed`, and a node `sherpa up` or `sherpa redeploy` was building becomes
`failed`. Nothing is removed automatically.

### `sherpa validate`

Validate the `manifest.toml` in the current directory without deploying.

## Node Access

### `sherpa ssh`

Open an interactive shell on a lab node over SSH, through the Sherpa server as the lab's
`.sherpa/ssh/config` describes. Sherpa has its own SSH client, so no `ssh` program needs to be
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
- A node's host key is checked against the lab's `.sherpa/ssh/known_hosts` file, which the server
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

Download lab files into `.sherpa/` (SSH config, SSH key, `lab-info.toml`, the nodes' host keys
in `ssh/known_hosts`, and each cluster's `k8s/kubeconfig-<cluster>` and
`talos/talosconfig-<cluster>`) for CLI use from a remote lab. Like `up`, it prints each Cilium
cluster's Gateway and Hubble UI addresses, and writes `ca/lab-ca.crt`, each Vault node's
`vault/vault-<node>.toml` and each Keycloak node's `keycloak/keycloak-<node>.toml`, all under
`.sherpa/`.

Only the lab's owner and admins can download a lab. The SSH key, `.sherpa/ssh/key`, is the lab's
own [key pair](architecture/ssh.md#lab-ssh-key), written only when the lab has nodes that log in
with it rather than your own keys. Labs created before Sherpa 0.5.15 use the server's shared key
instead, until they are destroyed.

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
| `--delay` | One-way delay in milliseconds, up to `274877` |
| `--jitter` | Delay jitter in milliseconds, up to `274877` |
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

On first connecting to a server whose certificate no public certificate authority issued, such
as the self-signed one Sherpa generates, `sherpa` shows the certificate and its SHA-256
fingerprint and asks whether to trust it. Check the fingerprint against the server's before you
answer: the server's administrator can read it with the command in
[Certificate Fingerprint](install-update/install/automated.md#certificate-fingerprint), and
`sherpad` logs it when it starts. A trusted certificate is saved, and later connections use it
without asking. The certificate is fetched from the server's HTTP port, `http_port` in
`[server_connection]` (`3031` by default).

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

Force clean all resources for a lab without requiring lab ownership. Admin only. It also
works on a lab the server has no record of, such as a lab folder left in `/opt/sherpa/labs`,
and removes the resources and folder named for the lab ID. The web UI's admin labs list shows
each lab's [phase](#lab-phases), so labs left `destroy failed` or `interrupted` are easy to find.
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

If no username is provided, changes the current user's password. To change your own password,
admins included, you are first asked for the current one. An admin resetting another user's
password is not. You are then asked for the new password twice, and it cannot be empty;
`SHERPA_USER_PASSWORD` is not used.

A password change logs the user out everywhere else. Changing your own password ends all your
other sessions, in the web UI and on other machines, and keeps the one you ran the command from.
An admin resetting another user's password ends all of that user's sessions.

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

If another change to the same user is saved at the same moment, the command fails with
`User '<username>' was changed by another request; reload and try again` and changes nothing.
Run it again.

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

Scan the images directory for on-disk images and import them to the database. A model's first
image found becomes its default only when the model has no default yet; see
[default versions](#default-versions).

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
| `--version`, `-v` | Version of the device model (required). See [image versions](#image-versions) |
| `--model`, `-m` | Model of the device (required) |
| `--default` | Set this image as the default version |

The image is copied to a temporary file next to its destination and moved into place only once
the copy is complete, and only then recorded in the database. An import that fails or is
interrupted leaves the server as it was; run it again.

Importing a version that is already on the server:

- If the file on the server has the same size as the source, the copy is skipped.
- If it has a different size, it is replaced with the source.
- If it has a different size and lab disks are built on it, the import is refused. Destroy
  those labs first, or import the image as a new version.

Settings an admin changed for the version in the web UI are kept.

#### Default versions

Each model with images has exactly one default version, used by nodes that do not name a
`version` in the manifest.

- The first version imported, pulled, downloaded or scanned for a model becomes its default.
- `--default` makes the new version the default. Without it, the default does not change, even
  when the version being imported again is the default.
- Deleting the default makes the most recently added remaining version the default, and the
  command prints which one.
- The default cannot be unset, in the web UI or otherwise; make another version the default
  instead, with `set-default`.

#### Image versions

An image version names the image's folder on the server and, for containers, its tag. It is
1 to 64 letters, digits, `.`, `_`, `+` or `-`, starting with a letter or digit, such as `24.4`,
`9-23-1` or `26.2R1.7-EVO`. `import`, `pull`, `download` and `delete` refuse any other version.

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

Delete an imported image from disk and the database. If it was the model's default, the most
recently added remaining version becomes the default; see [default versions](#default-versions).

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
