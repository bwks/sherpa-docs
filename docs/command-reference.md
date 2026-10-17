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

When the manifest declares [clusters](manifest.md#clusters-listcluster_object), `up` also
bootstraps each Kubernetes cluster, waits for its nodes to be Ready, and writes
`kubeconfig-<cluster>` and `talosconfig-<cluster>` to the current directory, readable only by
you. A cluster that is not ready in time is reported as a warning. See
[Talos Linux](nodes/linux/talos-linux.md).

### `sherpa down`

Stop all or a specific node in the lab.

With Tailscale enabled, a full shutdown also stops the gateway. Using `--node`
leaves the gateway alone.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target a specific node (omit for all nodes) |

### `sherpa resume`

Resume all or a specific stopped node in the lab.

Like `sherpa up`, resume waits for each VM or unikernel it boots to become ready,
showing progress as it goes. It uses the lab's `ready_timeout`, and each node's
`skip_ready_check` and `ready_port`, from the manifest the lab was created with. A node
that is not ready within the timeout is reported, but resume still succeeds. Containers
and paused nodes do not wait, because they resume an already running guest.

With Tailscale enabled, a full resume starts the gateway using its saved identity
before resuming nodes. No enrollment key is required. Using `--node` leaves the
gateway alone.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target a specific node (omit for all nodes) |

### `sherpa redeploy`

Destroy and recreate a single node with fresh ZTP configuration.

A worker in a Kubernetes [cluster](manifest.md#clusters-listcluster_object) rejoins with the
cluster's saved secrets. A cluster control plane cannot be redeployed.

| Flag | Description |
| ---- | ----------- |
| `--node`, `-n` | Target node to redeploy (required) |

### `sherpa destroy`

Destroy the lab and all its resources, including its Tailscale gateway and
identity volume when present. If either Tailscale removal fails, the server retains
database ownership and saved lab configuration so the owner or an admin can retry.
Other resources may already have been removed. See [cleanup recovery](architecture/networking/tailscale.md#recovery).

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

SSH to a device in the lab.

```
sherpa ssh <name>
```

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

### `sherpa server user list`

List all user accounts. Admin only.

### `sherpa server user delete`

Delete a user account. Admin only.

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
