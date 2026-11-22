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

The exit status says why:

| Status | Meaning |
| ------ | ------- |
| `0` | Success. |
| `1` | The command failed. |
| `75` | The server refused the command for now. `sherpa up`, `sherpa resume` or `sherpa redeploy`: the virtual machines and unikernels it would start do not fit in its memory ([host memory](configuration/sherpa.md#host_memory)). `sherpa up` or `sherpa redeploy`: host CPUs they pin are held by another node ([CPU pins held](manifest.md#cpu-pins-held)). Nothing was started; run the command again once other nodes are stopped or destroyed. |

`sherpa ssh` instead exits with the node shell's exit code, as described under
[`sherpa ssh`](#sherpa-ssh).

## Authentication

### `sherpa login`

Login to the Sherpa server. The username and password come from `SHERPA_USER_NAME` and
`SHERPA_USER_PASSWORD` when they are set, otherwise you are prompted for them. Use the variables
for scripts; the password is never taken as a flag, so it stays out of the process list and shell
history.

A refused login, whether the password is wrong, the username does not exist or the account is
locked, always says `username and/or password is incorrect`. Three failed logins in a row, on the
CLI, the REST API or the web UI, lock the account. A successful login sets the count back to 0.
A locked account is refused even with the right password until an admin unlocks it with
[`sherpa server user unlock`](#sherpa-server-user-unlock); it is never unlocked by time. See
[Locked accounts](help/troubleshooting.md#a-user-cannot-log-in-the-account-is-locked).

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
written by `sherpa up` and `sherpa download`, or else the one `manifest.toml` describes. When
both files are present and the lab's name in `manifest.toml` is not the one in
`.sherpa/lab-info.toml`, as after renaming the lab in `manifest.toml` or downloading another lab
into the folder, the commands refuse to run and name both labs. Destroy the old lab, or remove
`.sherpa/lab-info.toml`, before using the folder for the other one.

A `.sherpa/lab-info.toml` that is there but does not parse stops the command, even with a
`manifest.toml` beside it, and the error names the file and how to fix it:

```
.sherpa/lab-info.toml does not parse; restore it with 'sherpa download' of the lab, or remove it if this folder is for the lab named in manifest.toml
```

Run `sherpa download` of the lab to restore the file. If the folder is for the lab in
`manifest.toml`, remove the file instead. Only a folder with no `.sherpa/lab-info.toml` is the
lab of its `manifest.toml`.

A lab's ID is in `.sherpa/lab-info.toml`, so the commands find the lab whatever your computer
account is called: on another machine, as another user, or in a folder made by
`sherpa download`. A new lab's ID comes from your Sherpa username and the lab's name, so it is
the same on every machine you log in from, and two Sherpa users never share one.

A folder made by `sherpa download` has no `manifest.toml`. `inspect`, `ssh`, `console`, `down`,
`resume`, `destroy` and `link impair` work there. `up`, `redeploy` and `provision` build nodes
from the lab's manifest, so they need the folder the lab was started from, or a copy of its
`manifest.toml`, and say so:

```
This folder has no manifest.toml, and 'sherpa redeploy' needs the lab's source manifest. A folder made by 'sherpa download' has none: run 'sherpa redeploy' in the folder the lab was started from, or copy its manifest.toml here.
```

Every file Sherpa generates in the lab folder goes in a `.sherpa/` folder next to `manifest.toml`.
`.sherpa/` and the folders in it are readable only by you, and so are the secret files. A `.sherpa` that
is a symlink is refused.

### `sherpa new`

Create a new example `manifest.toml` in the current directory.

| Flag | Description |
| ---- | ----------- |
| `--force`, `-f` | Overwrite manifest file if one exists |

The generated manifest has a random lab name and two linked Linux nodes:

```toml
name = "absolute-grubworm"

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

| Flag | Description |
| ---- | ----------- |
| `--ssh-jump` | Reach the nodes for `ssh` provisioners through the Sherpa server, as `ssh -J <user>@<server>` does. Use it from a machine with no route to the lab's management network; see [SSH](architecture/ssh.md#jump-through-the-sherpa-server) |

The lab is reserved before anything is created: a second `sherpa up` of a lab that exists, or
that another `up` is creating, is refused at once with "Lab already exists", and does not touch
the existing lab. Destroy it first to start it again.

A container counts as ready once it has kept running for 5 seconds after it started and, if it
sets [`ready_check.port`](manifest.md#ready_check-object), that port answers. One whose
process exits before then, or before `sherpa up` finishes, is reported as a failed node, and
the rest of the lab is kept. The error gives its exit code and its last log lines; for the
whole log, run `docker logs <node>-<lab_id>` on the server. `sherpa up` then exits with an
error, saying the lab was only partly created.

The server refuses the lab before creating anything when its virtual machines and unikernels
do not fit in the server's memory, or on the NUMA node a node is held on strictly. The error
names the numbers that fell short, and `sherpa up` exits with status `75`
([exit status](#exit-status)). See [`[host_memory]`](configuration/sherpa.md#host_memory).
It is refused the same way, with status `75`, when a host CPU a node pins is held by another
node ([CPU pins held](manifest.md#cpu-pins-held)).

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

Once the lab is up, `sherpa up` prints a **Nodes** table: each node as `<name>.<lab_id>`, its
management IP, how to connect (`<ip>:<port>` for SSH), its model and its **Kind**
(`virtual_machine`, `container` or `unikernel`), so the two kinds of `arista_eos` or
`juniper_evolved` are told apart.

`up` writes the [lab CA](architecture/certificates.md) to `.sherpa/ca/lab-ca.crt`; for each
[Vault](nodes/hashicorp/hashicorp-vault.md) node Sherpa initialised, its address, root token and
unseal key to `.sherpa/vault/vault-<node>.toml`; and for each
[Keycloak](nodes/keycloak/keycloak-server.md) node, its admin and its `sherpa` realm's users and
passwords to `.sherpa/keycloak/keycloak-<node>.toml`; and for each
[SurrealDB](nodes/sql/surrealdb.md) node, its address and root user to
`.sherpa/surrealdb/surrealdb-<node>.toml`. The credential files are readable only by you.

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

Like `sherpa up`, resume waits for each VM or unikernel it boots, and each container it starts
that sets `ready_check.port`, to become ready, showing progress as it goes. It uses each node's
[ready check](manifest.md#ready_check-object) as the server recorded it when the lab was
created or the node last redeployed, and the lab's `ready_timeout` from the manifest the lab was
created with. A node that is not ready within the timeout is reported, but resume
still succeeds. Other containers, and paused nodes, do not wait: a paused node resumes an
already running guest. A paused
container is unpaused, a stopped one is started, and a running node is left as it is.
A booted node is `starting` until it is ready, then `running`; one that is not ready in time
stays `starting` until the server sees it answer.
A [Vault](nodes/hashicorp/hashicorp-vault.md#after-a-restart) node it starts again is unsealed
with its saved key; one Sherpa cannot unseal fails that node's result with the reason.

Resume refuses, with a reason in the node's result, a node that is `building` or `missing`, a
virtual machine that crashed, a container that is dead, and one that is between states, such as
shutting down or restarting. A crashed, dead or missing node needs `sherpa redeploy`. A lab that
is not `ready` (see [lab phases](#lab-phases)) is refused.

Before starting any node, resume checks that the stopped virtual machines and unikernels fit
in the server's memory, as `sherpa up` does, and refuses the whole resume if they do not.

A node that boots gets new link ends, so resume attaches its [links](architecture/networking/modes/point-to-point.md)
again, with their impairments. A stopped container that is started gets its data interfaces
made again, as its old ones went with it. Each link that is not attached is listed under the
node's line:

```
✅ vm1: Started and ready
   ℹ️ link vm1::eth1 <-> vm2::eth1 not attached: vm2 is down; it is attached when vm2 starts
   ⚠️ link vm1::eth2 <-> ctr1::eth1 not attached: <reason>
```

A link whose peer is down is expected: it is attached in both directions when the peer is
resumed. A link that failed carries no traffic until either end is resumed or redeployed again.
Neither fails the node or the command, since the node is up. Resuming one link end on its own
is therefore safe; links to nodes that are still down wait for them.

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
| `--ssh-jump` | Reach the node for `ssh` provisioners through the Sherpa server, as `ssh -J <user>@<server>` does. Use it from a machine with no route to the lab's management network; see [SSH](architecture/ssh.md#jump-through-the-sherpa-server) |

The rebuilt node's links are attached again. Links that are not attached are listed after the
result, as for [`sherpa resume`](#sherpa-resume): a link whose peer is down waits for that peer
and is attached when it starts, and does not fail the redeploy.

When the node has [provisioners](architecture/provisioners/overview.md), the CLI sends a container's
secret files with the redeploy, and runs `ssh` provisioners once the node is back.

The node is rebuilt from the image `sherpa up` would give it: the manifest's `version` of its
model and kind, or else their default version. So to move a node to another version, such as a
container node to a new tag, change its `version` and redeploy it. Its model and kind cannot
change. Once the node is rebuilt from another version, the version it ran before is no longer in
use by it and can be deleted.

The server checks the manifest, the node's image and the server's resources before it destroys
the node, so a refused redeploy leaves the node running as it was. A redeploy that fails once the
node is destroyed marks it `failed` in `sherpa inspect`; fix the cause and redeploy it again.
While it is rebuilt the node is `building`, then `starting`, and `running` once ready. A
container that runs Vault or Keycloak is `running` only once they are restored, and one that
sets `ready_check.port` only once that port answers; one whose port does not answer in time is
reported not ready, and the redeploy still succeeds. The node's `ready_check` is recorded from
the manifest you redeploy with, so a changed port is the one `sherpa resume` and the server's
scanner check from then on.

#### Redeploying from the web UI

The web UI's **Redeploy** button rebuilds the node from the lab's
[definition](architecture/database.md#lab-definitions), the manifest as you wrote it, which holds
no file contents and no values of `$VAR` variables. It redeploys a node that needs none of them,
with its other settings as last deployed. A node that needs any of these is refused, and left as
it was:

- `ztp.config`
- `text_files` or `systemd_units`
- `startup_scripts`
- `environment_variables` with a `$VAR` value
- `provisioners`, which only the CLI runs

The message names the node and what it needs, for example:

```
Node 'dev01' cannot be redeployed from the web UI: it needs ztp.config, text_files, which the server does not keep. Run `sherpa redeploy -n dev01` from the lab folder
```

Run `sherpa redeploy -n <node>` from the lab's folder instead: the CLI reads the files and
variables there.

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
| `--ssh-jump` | Reach the nodes for `ssh` provisioners through the Sherpa server, as `ssh -J <user>@<server>` does. Use it from a machine with no route to the lab's management network; see [SSH](architecture/ssh.md#jump-through-the-sherpa-server) |

It stops with `Only the owner of lab '<id>' can connect to its nodes` when the folder's
`.sherpa/lab-info.toml` names a lab owned by someone else, as in an admin's copy of another
user's lab folder. A folder with only a manifest is always your own lab.

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

A destroy that waited behind another destroy of the same lab, and finds it gone, succeeds.

If the server cannot remove every resource, destroy prints what failed and exits with an
error, and the lab is `destroy failed` (see [lab phases](#lab-phases)). While the lab still exists on the server, the local files are kept, so nodes that are
still running stay reachable, and running `sherpa destroy` again removes them.

| Flag | Description |
| ---- | ----------- |
| `--yes`, `-y` | Skip confirmation prompt |

### `sherpa inspect`

Inspect the current lab environment. Shows [node states](#node-states), links, and lab details.
A container node's state is read from Docker each time, so a container that has exited since
it was recorded `running` shows as `stopped` at once, before the server's
[scanner](configuration/sherpa.md#scanner) records it.
The lab details include the manifest's **Description**, and **Client Host** and
**Client Folder**, the machine and directory `sherpa up` ran in. Labs started from the web UI or the API have neither.
For Tailscale-enabled labs, refreshes gateway state, Tailscale addresses, advertised
management routes, route approval, and warnings. This is the default command when
no subcommand is specified.

Inspect shows no console address or VNC port: connect with `sherpa console` and `sherpa vnc`.

A [Vault](nodes/hashicorp/hashicorp-vault.md#when-vault-stays-sealed) node the server cannot
unseal shows why under its state, such as `Vault sealed: key refused`.

#### Link states

The **Links** table has a **State** column, with what the server last found or left each
[P2P link](architecture/networking/modes/point-to-point.md#when-a-node-restarts) in:

| State | Meaning |
| ----- | ------- |
| `attached` | Both ends exist and redirect to each other, with the link's impairments. |
| `peer down: <node>` | `<node>` is stopped or paused, or its virtual machine or container is gone. The other end's interface has no carrier. The link is attached again, with carrier, when `<node>` starts or is unpaused. |
| `failed: <reason>` | The link could not be attached. It carries no traffic, and neither end's interface has carrier, until it is attached again, by the next scan, a resume or a redeploy. |
| `not checked` | The server has not checked the link since it started: the [scanner](configuration/sherpa.md#scanner) checks each lab every `scanner.interval_secs` (30 seconds by default), so this shows only for that long after the server starts, or while the scanner is disabled. |

The state comes from the last scan, resume or redeploy, so a change made since then shows at
the next scan. A link's interfaces lose and get back their carrier with its state; see
[When a Neighbour Stops](architecture/networking/modes/point-to-point.md#when-a-neighbour-stops).

#### Node states

| State | Meaning |
| ----- | ------- |
| `building` | `sherpa up` or `sherpa redeploy` is creating the node. Nothing else can stop, start or redeploy it until that finishes. |
| `starting` | The node is started but not ready yet: its ready check has not passed. The server's [scanner](configuration/sherpa.md#scanner) keeps checking its ready port, and records it `running` once it answers. |
| `running` | The node is ready: its ready check passed, or it has `ready_check.skip`. A container is ready once it has kept running for 5 seconds after it started and its `ready_check.port`, if it sets one, answers. |
| `stopped` | The node is shut down or paused, by `sherpa down` or outside Sherpa, or its container's process exited after it was ready. |
| `failed` | An operation on the node failed, such as a redeploy or a container that exited during `sherpa up` before it was ready, or its virtual machine crashed or its container died. It stays `failed` until you stop, resume or redeploy it. |
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

Open an interactive shell on a lab node over SSH, as the lab's `.sherpa/ssh/config` describes:
straight to the node, from the Sherpa server or a machine on the lab's
[tailnet](architecture/networking/tailscale.md). Sherpa has its own SSH client, so no `ssh`
program needs to be installed.

```
sherpa ssh <name>
sherpa ssh <name> --ssh-jump
```

| Flag | Description |
| ---- | ----------- |
| `--ssh-jump` | Go through the Sherpa server as a jump host, as the logged-in Sherpa user, as `ssh -J <user>@<server>` does. Use it from a machine with no route to the lab's management network; see [SSH](architecture/ssh.md#jump-through-the-sherpa-server) |


- The terminal type (`TERM`) and window size are passed to the node, and resizing the window
  resizes the remote terminal.
- Once connected, it prints `Connected to <node>.<lab-id>. Escape: ~. at the start of a line.`,
  and `Connection to <node>.<lab-id> closed.` when the session ends.
- Type `~.` at the start of a line to disconnect, for example from a node that stopped
  answering. Type `~~` to send a single `~`.
- `sherpa ssh` exits with the exit code of the node's shell, or 255 if the node did not
  report one. Windows nodes do not report it, so it is 0 there.
- A node this machine has no route to fails at once, with `<node> at <address>:22 is not
  reachable from this machine (<cause>). Use --ssh-jump to go through the Sherpa server, or join
  the lab's tailnet and accept its routes.` It waits at most 10 seconds for the node to answer.
- With `--ssh-jump`, the first time you connect to a Sherpa server, you are shown its host key
  fingerprint and asked to confirm it, as with OpenSSH. A confirmed key is added to `~/.ssh/known_hosts`. A
  server whose key has changed is refused.
- A node's host key is checked against the lab's `.sherpa/ssh/known_hosts` file, which the server
  fills in as nodes become ready, so you are not asked about it. If the node's key has
  changed, as after a restart from the web UI, the new key is fetched from the server with a
  warning. See [Node Host Keys](architecture/ssh.md#node-host-keys).
- If your key has a passphrase, or the node or the Sherpa server needs your password, you are
  asked for it, as with OpenSSH. A key loaded in your SSH agent needs no prompt. See
  [SSH](architecture/ssh.md).
- It stops before connecting, with `Only the owner of lab '<id>' can connect to its nodes`, when
  the folder's `.sherpa/lab-info.toml` names a lab owned by someone other than the logged-in
  user, as in an admin's copy of another user's lab folder. A folder with only a manifest is
  always your own lab.

### `sherpa console`

Open the serial console of a virtual machine or unikernel node in your terminal. `sherpa console`
connects to the Sherpa server's API over TLS with your login token, so it works from any machine
with the CLI, remote and Windows clients included. It makes no SSH connection, so you need no SSH
key or account on the server, and no `telnet` program. See [Serial Console](architecture/console.md).

```
sherpa console <name> [--force]
```

| Flag | Description |
| ---- | ----------- |
| `--force` | Take the console over from a session of your own, for example one left open on another machine |

- Once connected, it prints `Connected to the console of <node> in lab <lab>. Escape: Ctrl+] or
  ~. at the start of a line.`, and `Connection to the console of <node> closed.` when the
  session ends. Press Enter to see the node's prompt.
- Press `Ctrl+]` anywhere, or type `~.` at the start of a line, to disconnect. Type `~~` to send
  a single `~`. `sherpa console` exits with code 0 when you disconnect or the console closes.
- Only the lab's owner can open a node's console. An admin is refused too, as is anyone else, with
  `Access denied: only the owner of lab '<lab-id>' can open its consoles`. The server decides.
- A console serves one session at a time. If another session holds it, `sherpa console` is refused
  at once with `The console of <node> is in use by <user> from <client-ip> since <time> UTC. Close
  that session, or take it over with 'sherpa console <node> --force'.`
- With `--force`, the session that held the console ends with `Connection to the console of
  <node> closed: Taken over by <user> from <ip> since <time> UTC.` `--force` takes over only your
  own sessions.
- A session also ends when the node stops (`The node's console closed: the node stopped.`) and
  when your login ends, by `sherpa logout`, a password change or the user being deleted (`Your
  login session ended. Log in again with 'sherpa login'.`). The server checks the login every 30
  seconds.
- Disconnecting does not log the node's session out, because the serial port does not tell the
  node. Log out before you disconnect. Only the lab's owner can attach to the console, so a
  session left logged in is reachable only by the owner.
- Refusals before connecting:
    - `Node '<node>' is not running. Start it with 'sherpa resume'.`
    - `<node> is a container, and containers have no serial console. Connect with 'sherpa ssh
      <node>' instead.` Container nodes have no serial console; use `sherpa ssh`, or `docker exec`
      on the server.
    - `Not logged in to the Sherpa server, or the login has expired: run 'sherpa login'.`
    - `The Sherpa server has no console route: it is older than this client. Update the server to the client's version.`
- It needs you to be logged in, and works in a folder made by `sherpa download`, as it takes the
  lab from the folder's `.sherpa/lab-info.toml`.

### `sherpa vnc`

Relay the VNC console of a virtual machine node to a VNC viewer on your machine. `sherpa vnc`
listens on `127.0.0.1` on a free port, prints the address, and relays each connection your viewer
makes to the Sherpa server's API over TLS with your login token, until you press `Ctrl+C`. It
makes no SSH connection. See
[VNC](architecture/vnc.md).

```
sherpa vnc <name> [--force]
```

| Flag | Description |
| ---- | ----------- |
| `--force` | Take the VNC console over from a session of your own, for example one left open on another machine. Applies to every connection |

- It prints `VNC console of <node> in lab <lab>: connect a VNC viewer to 127.0.0.1:<port>. Ctrl+C
  to stop.` Point your viewer at that address.
- For each connection it prints `Viewer <address> connected to the VNC console of <node>.`, and
  when it ends `Viewer <address> disconnected from the VNC console of <node>.`, or `The VNC
  console of <node> closed for viewer <address>: <reason>` when the server ended it.
- `Ctrl+C` stops it with `Stopped relaying the VNC console of <node>.` and exit code 0.
- Only the lab's owner can open a node's VNC console, admins included. `sherpa vnc` asks the
  server before it opens a port: a refusal ends it at once with the reason and exit code 1, and
  no address is printed, such as `Access denied: only the owner of lab '<lab-id>' can open its
  consoles` or `Node '<node>' is not running. Start it with 'sherpa resume'.`
- A VNC console serves one session at a time, apart from the node's serial console. When another
  session holds it as `sherpa vnc` starts, it prints the address, then `The VNC console of <node>
  is in use by <user> from <client-ip> since <time> UTC: viewers are refused until that session
  ends, or take it over with 'sherpa vnc <node> --force'.`, and keeps listening. A viewer that
  connects while the console is held is refused with `The VNC console of <node> is in use by ...
  Close that session, or take it over with 'sherpa vnc <node> --force'.`; `sherpa vnc` prints it
  and keeps listening. So it does for a node that stopped after it started.
- Refusals that end `sherpa vnc`, as it starts or when a viewer connects:
    - `<node> is a container, and containers have no VNC console. Connect with 'sherpa ssh
      <node>' instead.`
    - `<node> is a unikernel, and unikernels have no VNC console. Use 'sherpa console <node>'
      instead.`
    - `Not logged in to the Sherpa server, or the login has expired: run 'sherpa login'.`
    - `The Sherpa server has no VNC console route: it is older than this client. Update the
      server to the client's version.`
- Other accounts on your machine can connect to the port while `sherpa vnc` runs. The node's VNC
  server asks for no password.
- It works in a folder made by `sherpa download`.

### `sherpa download`

Download lab files into `.sherpa/` (SSH config, `lab-info.toml`, the nodes' host keys
in `ssh/known_hosts`, and each cluster's `k8s/kubeconfig-<cluster>` and
`talos/talosconfig-<cluster>`) for CLI use from a remote lab. Like `up`, it prints each Cilium
cluster's Gateway and Hubble UI addresses, and writes `ca/lab-ca.crt`, each Vault node's
`vault/vault-<node>.toml`, each Keycloak node's `keycloak/keycloak-<node>.toml` and each SurrealDB
node's `surrealdb/surrealdb-<node>.toml`, all under `.sherpa/`.

It writes no `manifest.toml`: the server keeps the lab's definition, but not your manifest's
files or secrets. Every command that reaches the lab's nodes works in the folder (`inspect`,
`ssh`, `console`, `vnc`, `down`, `resume`, `destroy` and `link impair`); `up`, `redeploy` and
`provision` need the lab's own manifest. See [Lab Lifecycle](#lab-lifecycle).

Only the lab's owner can download a lab, admins included: the files hold the SSH config, the
nodes' host keys, the Talos, Vault, Keycloak and SurrealDB credentials and the lab CA, which let
the holder log in to the nodes. Anyone else is refused with `Only the owner of lab '<id>' can perform this
operation`. No SSH key is downloaded: nodes take your own
keys (see [SSH](architecture/ssh.md#logging-in-to-nodes)).

```
sherpa download <lab_id>
```

| Flag | Description |
| ---- | ----------- |
| `--force`, `-f` | Overwrite existing lab files if they exist |

## Link Commands

### `sherpa link impair`

Change the impairment on a running P2P link. Run it in the lab's folder, which can be one
made by `sherpa download`: the link is found by either of its ends among the lab's links, as
`sherpa inspect` lists them.

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
once and is kept across `sherpa down`/`sherpa resume` and redeploying either end. The node at the
end each changed direction leaves through must be up. A change the server cannot make in full fails and is undone, so the link
keeps its previous impairment; `--clear` fails rather than report a direction clear whose
impairment could not be removed. See [Link Impairment](api-reference.md#link-impairment) for the
API.

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
| `--kind` | Kind of the image: `virtual_machine`, `container` or `unikernel`. Without it, the model's default kind. `generic` has no default, so it needs `--kind`; the containers of `arista_eos` and `juniper_evolved` need `--kind container` |

It prints the same table as [`sherpa server image show`](#sherpa-server-image-show).

### `sherpa image list`

List available images.

```
sherpa image list [model]
```

| Flag | Description |
| ---- | ----------- |
| `--kind` | List images of one kind only: `virtual_machine`, `container` or `unikernel`. Without it, every kind is listed |

## Certificate Commands

Manage trusted server certificates using the Trust-On-First-Use (TOFU) system.

On first connecting to a server whose certificate no public certificate authority issued, such
as the self-signed one Sherpa generates, `sherpa` shows the certificate and its key pin, the
SHA-256 of the server's public key, and asks whether to trust it. Check the key pin against the
server's before you answer: the server's administrator can read it with the command in
[Server Key Pin](install-update/install/automated.md#server-key-pin), and `sherpad` logs it
when it starts. A trusted certificate is saved, and later connections trust the server whenever
it presents the same public key, so a certificate the server renews with its key is trusted
without asking. A server that presents another key is refused, unless a public certificate
authority issued its certificate and `validate_certs` is on; delete the saved certificate with
`sherpa cert delete` to be asked again. The certificate is fetched from the server's HTTP port, `http_port` in
`[server_connection]` (`3031` by default).

`cert show`, `cert trust` and `cert delete` take the server as a host (`10.100.58.10`), a
`host:port` (`10.100.58.10:3030`) or a `ws://` or `wss://` URL (`wss://10.100.58.10:3030/ws`).
A host without a port uses the Sherpa server's port, `3030`. Other URLs, such as `https://`
ones, are refused.

### `sherpa cert list`

List all trusted certificates, with each one's subject and key pin.

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
prints its path and size. The backup stays on the server. It does not hold the
[database key](architecture/database.md#database-key), `/opt/sherpa/.secret/db.key`, so keep a
copy of the key alongside your backups, stored separately from them. See [Database backups](architecture/database.md#backups) for
restoring one.

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

The command takes no SSH keys: each user adds their own with
[`ssh-key add`](#sherpa-server-user-ssh-key) or on the **Profile** page, and cannot start a lab
until they have. An admin cannot add a key to another account.

Reserved names include `admin`, `root` and `sherpa`, system accounts such as `daemon` and
`nobody`, names starting with `systemd-`, and the default users of common images and network
devices, such as `ubuntu`, `core`, `ec2-user`, `cisco` and `cumulus`.

### `sherpa server user list`

List all user accounts. Admin only. Each user's entry shows whether they have set a
[device password](architecture/device-password.md): `Device password: set` or `not set`.

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

### `sherpa server user unlock`

Unlock an account that three failed logins in a row locked, and set its count of failed logins
back to 0. Admin only. The user can then log in with their password.

```
sherpa server user unlock <username>
```

Unlocking an account that is not locked is not an error; an unknown username is. Admins can also
unlock an account with the **Unlock** button in the **Locked** column of the **Users** admin page,
which shows the button only for locked accounts. When no admin can log in, root unlocks an
account, the built-in `admin` included, on the server with
[`sherpad user unlock`](#sherpad-user-unlock); see
[The built-in admin account is locked](help/troubleshooting.md#the-built-in-admin-account-is-locked).

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
An admin resetting another user's password ends all of that user's sessions. A reset does not
unlock a locked account; unlock it with [`sherpa server user unlock`](#sherpa-server-user-unlock).

### `sherpa server user info`

Show detailed user information.

```
sherpa server user info [username]
```

If no username is provided, shows the current user's information, including
`Device password: set` or `not set`. The device password itself is never shown.

### `sherpa server user device-password`

Set your own [device password](architecture/device-password.md), your password on lab nodes.

```
sherpa server user device-password
```

It asks for your Sherpa login password, then the new device password twice. It takes no
arguments or flags: passwords are always typed at the prompt and `SHERPA_USER_PASSWORD` is not
used. It sets only your own: administrators cannot set another user's, and the built-in `admin`
account has none. The device password must meet the
[rules](architecture/device-password.md#rules) and differ from your login password. Setting it
again replaces it.

### `sherpa server user ssh-key`

Manage SSH public keys. You need at least one registered key to start labs; see
[SSH Keys](architecture/ssh-keys.md). Each command acts on your own account. Admins can list
and remove any user's keys with `--user`, but only a user can add a key to their own account:
`add` takes no `--user`, and the server refuses a key for any other account, admins included.

```
sherpa server user ssh-key list [--user <username>]
sherpa server user ssh-key add <key or .pub file>
sherpa server user ssh-key remove <key, .pub file or SHA256 fingerprint> [--user <username>]
```

| Flag | Description |
| ---- | ----------- |
| `--user` | `list` and `remove` only: user whose keys to manage (defaults to the logged-in user) |

`list` shows each key's type, `SHA256:` fingerprint and comment. Adding a key that is already
registered, even with a different comment, is refused.

If another change to the same user is saved at the same moment, the command fails with
`User '<username>' was changed by another request; reload and try again` and changes nothing.
Run it again.

## Server Image Commands

Image management commands. All require admin privileges.

An image is a model, a kind and a version. Every command that names one image takes `--kind`,
and without it uses the model's default kind; `kind` in the manifest works the same way, see
[`kind`](manifest.md#kind-string). A kind the model does not take is refused, naming the kinds it
takes. `list` and `scan` take `--kind` to work on one kind only.

Most models take one kind, so `--kind` is not needed on them. `arista_eos` and
`juniper_evolved` default to the virtual machine: their container images (cEOS-lab and
cJunosEvolved) need `--kind container` on every command that names one image. `generic` has no
default kind, so every command that names a `generic` image needs `--kind`, and without it is
refused: `Model 'generic' has no default kind; set its kind to one of: virtual_machine,
container, unikernel`.

```
sherpa server image show arista_eos --kind container
sherpa server image delete --model juniper_evolved --kind container --version 26.2R1.7
```

### `sherpa server image show`

Show detailed information about an image.

```
sherpa server image show <model>
```

| Flag | Description |
| ---- | ----------- |
| `--version` | Show a specific version (defaults to the default version) |
| `--kind` | Kind of the image: `virtual_machine`, `container` or `unikernel`. Without it, the model's default kind. `generic` has no default, so it needs `--kind`; the containers of `arista_eos` and `juniper_evolved` need `--kind container` |

The table names each row by its key in the image's JSON. It shows the settings every kind takes
(`model`, `kind`, `version`, `default`, `memory`, `cpu.count`, `interfaces.data_count`,
`interfaces.management`, `interfaces.reserved_count`), then the image's own kind's group:

| Kind | Rows |
| ---- | ---- |
| Virtual machine | `vm.os_variant`, `vm.cpu.architecture`, `vm.cpu.model`, `vm.cpu.vmx`, `vm.machine.kind`, `vm.machine.bios`, `vm.boot_disk.bus`, `vm.cdrom.image`, `vm.cdrom.bus`, `vm.interfaces.kind`, `vm.interfaces.mtu`, `vm.ztp.method` |
| Container | `container.repo`, `container.ztp.method` |
| Unikernel | `unikernel.boot_mode`, `unikernel.cpu.architecture`, `unikernel.cpu.model`, `unikernel.machine.kind`, `unikernel.interfaces.kind`, `unikernel.interfaces.mtu` |

`sherpa server --output json image show <model>` prints the JSON itself; see
[Node images](api-reference.md#node-images).

### `sherpa server image list`

List all images.

```
sherpa server image list [model]
```

| Flag | Description |
| ---- | ----------- |
| `--kind` | List images of one kind only: `virtual_machine`, `container` or `unikernel`. Without it, every kind is listed |

### `sherpa server image scan`

Record images that are on the server but not in its database: VM and unikernel disk images in
the images directory, and container images in local Docker, such as ones pulled with
`docker pull`. A model's first image found becomes its default only when the model has no
default yet; see [default versions](#default-versions). A version already recorded is reported
as `already_exists` and left as it is.

```
sherpa server image scan [--kind <kind>] [--dry-run]
sherpa server image scan --kind container --model <model> --repo <repo> [--dry-run]
```

| Flag | Description |
| ---- | ----------- |
| `--kind` | Scan images of one kind only: `virtual_machine`, `container` or `unikernel`. Without it, every kind is scanned |
| `--dry-run` | Show what would be imported without making changes |
| `--model`, `-m` | Container model to record the local tags of `--repo` for. Needs `--repo` and `--kind container` |
| `--repo`, `-r` | Image repository without a tag, such as `mysql` or `ghcr.io/nokia/srlinux`. Needs `--model` |

Container images are matched by repository, and each local tag of a matching repository is
recorded as a version, with the repository a node of that version runs:

- Without `--model` and `--repo`, each container model with a built-in repo, such as
  `nokia_srlinux` (`ghcr.io/nokia/srlinux`) or `nats_bus` (`nats`), gets that repo's local tags.
  The models with no built-in repo (`mysql_db`, `postgresql_db`, and `generic` containers) are
  listed as skipped, since a local image cannot be told apart as one of them.
- With `--model` and `--repo`, only that repo's local tags are recorded, as versions of that
  model. This records images for a model with no built-in repo, or for a built-in model from
  another repo, such as a mirror. Nothing else is scanned.

```
docker pull mysql:8.4
sherpa server image scan --kind container --model mysql_db --repo mysql
```

Docker matches the repo to local images as `docker images <repo>` does, so the repo matches only
that repository, never one it is a prefix of (`nats` does not match `natsio/nats-box`). Give a
Docker Hub repo by its short name (`mysql`) or in full as `docker.io/library/<name>`
(`docker.io/library/mysql`); both match the image Docker lists as `mysql`. `docker.io/mysql` and
`index.docker.io/library/mysql` match nothing, and the scan says no local images were found.
Tags that are not valid [image versions](#image-versions) are left out.

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
| `--kind` | Kind of the image: `virtual_machine`, `container` or `unikernel`. Without it, the model's default kind. `generic` has no default, so it needs `--kind`; the containers of `arista_eos` and `juniper_evolved` need `--kind container` |
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
| `--kind` | Kind of the image, which decides between a registry pull (`container`) and a download (`virtual_machine`): `virtual_machine`, `container` or `unikernel`. Without it, the model's default kind. `generic` has no default, so it needs `--kind`; the containers of `arista_eos` and `juniper_evolved` need `--kind container` |
| `--version`, `-v` | Version of the image |
| `--repo`, `-r` | Container image reference with a tag: a Docker Hub image by its short or full name (`nats:2.11` or `docker.io/library/nats:2.11`), or an image in another registry (`registry.io/account/image:version` or `localhost:5000/image:1`); digests (`@sha256:...`) are not supported |
| `--url`, `-u` | VM image download URL |
| `--default` | Set this image as the default version |

The tag is the version Sherpa records. Sherpa also records the repo as you wrote it, and container
nodes of that version run that repo unless the manifest sets `image` on the node. This applies to
models with a built-in repo too. For example, `frr_linux` pulled with
`--repo mirror.example/frrouting/frr:10.5.2` runs the mirror's image, not
`quay.io/frrouting/frr`. `sherpa up` and `sherpa redeploy` check that Docker has the image before
they create anything.

### `sherpa server image delete`

Delete an imported image: its record, then a VM's or unikernel's file, or a container's
Docker image (its repo at its version, through the Docker API; another tag of the same image,
such as the one it was pulled as, is kept). If it was the model's default, the most recently
added remaining version becomes the default; see [default versions](#default-versions).
A VM and a unikernel of the same model and version share a folder under
`/opt/sherpa/images/<model>/<version>/`: deleting one removes only its own file, and the folder
goes with the last file in it.

The delete is refused while the image is in use:

- a VM or unikernel image while a lab disk is built on it, whether its VM is running or stopped,
  naming the disk; disks built on other images do not stop it;
- a container image while a running container runs it, naming the containers;
- any image a lab node records: destroy the lab, or redeploy the node onto another version.

```
sherpa server image delete --model <model> --version <version>
```

| Flag | Description |
| ---- | ----------- |
| `--model`, `-m` | Model of the device image to delete (required) |
| `--kind` | Kind of the image: `virtual_machine`, `container` or `unikernel`. Without it, the model's default kind. `generic` has no default, so it needs `--kind`; the containers of `arista_eos` and `juniper_evolved` need `--kind container` |
| `--version`, `-v` | Version of the device image to delete (required) |

### `sherpa server image set-default`

Set the default version for an image model.

```
sherpa server image set-default --model <model> --version <version>
```

| Flag | Description |
| ---- | ----------- |
| `--model`, `-m` | Model of the device image (required) |
| `--kind` | Kind of the image: `virtual_machine`, `container` or `unikernel`. Without it, the model's default kind. `generic` has no default, so it needs `--kind`; the containers of `arista_eos` and `juniper_evolved` need `--kind container` |
| `--version`, `-v` | Version to set as default (required) |

## Server Daemon

`sherpad` runs on the server. Besides `start`, `stop`, `restart`, `status`, `logs` and `doctor`,
it has these setup and recovery commands.

### `sherpad check-database`

Check, without changing it, that this release can use the server's database, as it does when
it starts. The update script runs the new release's check before installing it. Run it as the `sherpa`
user, while `sherpad` is stopped. It takes no flags.

### `sherpad init`

Initialize the server: directories, `sherpa.toml`, libvirt network and storage pool,
the database, the built-in `admin` account and a first user account. See the
[Quickstart](quickstart.md) for the accounts and unattended use.

Run it as the `sherpa` user, `sudo -u sherpa -H sherpad init`, so that `sherpad`, which runs as
`sherpa`, can read what it writes. It refuses to run as any other account, root included, and stops
before changing anything. It writes `sherpa.toml` with mode `600` whatever your umask,
and `--force` gives a rewritten file that mode too.

| Flag | Description |
| ---- | ----------- |
| `--force` | Overwrite an existing config |
| `--server-ipv4` | Server listen IPv4 address, default `0.0.0.0` (env: `SHERPA_SERVER_IPV4`) |
| `--server-ipv6` | Server listen IPv6 address, if any (env: `SHERPA_SERVER_IPV6`) |
| `--ws-port` | Server listen port, default `3030` (env: `SHERPA_SERVER_WS_PORT`) |
| `--http-port` | HTTP certificate endpoint port, default `3031` (env: `SHERPA_SERVER_HTTP_PORT`) |
| `--management-prefix-ipv4` | IPv4 prefix lab management `/24` subnets are taken from, default `172.31.0.0/16` (env: `SHERPA_MANAGEMENT_PREFIX_IPV4`) |
| `--management-prefix-ipv6` | IPv6 prefix lab management `/64` subnets are taken from (env: `SHERPA_MANAGEMENT_PREFIX_IPV6`). Left out, none is written and labs use `fd00:b00b::/48` |

The address, port and prefix values are written only when `init` writes `sherpa.toml`: an
existing config is kept, and `--force` rewrites it. The IPv4 management prefix must be `/24` or
shorter, and not a `x.x.0.0/24`, with room for a lab's `/24`. The IPv6 management prefix must be
`/63` or shorter, since the first `/64` is not given to labs. `sherpad init` refuses any other
value before changing anything. To change the prefix of a server that already has a config, see
[Changing the Ranges](architecture/networking/ip-addressing.md#changing-the-ranges).

Values come from the flags or the environment variables only; `/opt/sherpa/env/sherpa.env` is not
read. The install script prints the `sherpad init` command with the address and ports you gave
it. The database is a file `sherpad` manages itself.

### `sherpad user unlock`

Unlock an account that three failed logins in a row locked, the built-in `admin` included, and
set its count of failed logins back to 0, when no admin can log in to do it with
[`sherpa server user unlock`](#sherpa-server-user-unlock). It works on the database directly,
which `sherpad` holds while it runs, so stop `sherpad` first and start it again after:

```
sudo systemctl stop sherpad
sudo -u sherpa sherpad user unlock <username>
sudo systemctl start sherpad
```

While `sherpad` is running it refuses, saying to stop it, and changes nothing. Run it as the
`sherpa` user; it refuses any other account, root included, and changes nothing. An unknown
username is an error; an account that is not locked is not, and it says so.
