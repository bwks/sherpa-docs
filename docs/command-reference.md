# Command Reference

## Global Flags

These flags are available on all commands.

| Flag | Description |
| ---- | ----------- |
| `--server-url` | Remote server URL for WebSocket RPC (env: `SHERPA_SERVER_URL`) |
| `--insecure` | Skip TLS certificate validation (development only) |

## Authentication

### `sherpa login`

Login to the Sherpa server. Prompts for username and password.

### `sherpa logout`

Logout from the Sherpa server. Removes the stored authentication token.

### `sherpa whoami`

Show the current authentication status and user information.

## Lab Lifecycle

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

When `[tailscale]` is enabled, resolves the auth key from the client environment
variable named by `auth_key_env` and creates a gateway for the lab. Enrollment
requires WSS with certificate validation enabled. Pending route approval produces
a warning without failing creation. See the [Tailscale guide](architecture/networking/tailscale.md).

When the manifest declares [Talos clusters](manifest.md#talos_clusters-listtalos_cluster_object), `up` also
bootstraps each Kubernetes cluster, waits for its nodes to be Ready, and writes
`kubeconfig-<cluster>` and `talosconfig-<cluster>` to the current directory, readable only by
you. A cluster that is not ready in time is reported as a warning. See
[Talos Linux](nodes/linux/talos-linux.md).

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

The CLI prints the result for each node and exits with an error if any node was not
provisioned.

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

| Flag | Description |
| ---- | ----------- |
| `--yes`, `-y` | Skip confirmation prompt |

### `sherpa inspect`

Inspect the current lab environment. Shows node states, links, and lab details.
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
- The login to the Sherpa server cannot prompt for a password or key passphrase. Use a key
  loaded in your SSH agent, or a key without a passphrase. See [SSH](architecture/ssh.md).

### `sherpa console`

Connect to a device via serial console over Telnet.

```
sherpa console <name>
```

### `sherpa download`

Download lab files (SSH config, SSH key, lab-info, and each cluster's `kubeconfig-<cluster>`
and `talosconfig-<cluster>`) for CLI use from a remote lab.

```
sherpa download <lab_id>
```

| Flag | Description |
| ---- | ----------- |
| `--force`, `-f` | Overwrite existing lab files if they exist |

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

## Certificate Commands

Manage trusted server certificates using the Trust-On-First-Use (TOFU) system.

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

If no username is provided, changes the current user's password.

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

### `sherpa server image scan`

Scan the images directory for on-disk images and import them to the database.

| Flag | Description |
| ---- | ----------- |
| `--container` | Scan container images |
| `--unikernel` | Scan unikernel images |
| `--virtual-machine` | Scan virtual machine images |
| `--dry-run` | Show what would be imported without making changes |

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
| `--repo`, `-r` | Full container image reference (e.g., `registry.io/account/image:version`) |
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
