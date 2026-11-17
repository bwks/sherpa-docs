# Sherpa

The update script replaces the Sherpa binaries with a release from GitHub and restarts `sherpad`.
It does not reinstall system packages or change users, and creates the
[blank disks](../install/automated.md#blank-disks) that are missing. It updates the `sherpa` CLI on the server
only: update it on every other client too, to the same version, as described in
[Client](client.md).

!!! danger

    Piping to sudo can be dangerous. You are strongly encouraged to review the below script
    before executing the below command.

Update to the latest release:

```
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh | sudo bash
```

Update to a specific release, or reinstall the current one:

```
curl -fsSLO https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh
sudo bash sherpa_update.sh --version v0.5.0
sudo bash sherpa_update.sh --force
```

Take a [database backup](../../architecture/database.md#backups) before updating, and keep a
copy of the [database key](../../architecture/database.md#database-key),
`/opt/sherpa/.secret/db.key`, alongside it but separately. From this release `sherpad` encrypts
passwords in the database with that key, and does not start on a database without it. The update
script creates `/opt/sherpa/.secret` (mode `700`, owned by `sherpa`) if it is missing.

On every run, even when there is nothing to install, the update script creates each
[blank disk](../install/automated.md#blank-disks) that is missing from
`/opt/sherpa/images/blank_disk/`, before it stops `sherpad`. It never changes a disk that is
there. Servers installed before the install script made these disks lack some of them, and nodes
that boot from one, such as Cumulus Linux, Juniper vEvolved, Cisco IOSv, IOSvL2 and ISE, MikroTik
CHR and Flatcar Linux, fail to start without it. If `qemu-img`, `mkfs.fat`, `mkfs.vfat` or
`mkfs.ext4` is missing, the script first installs `qemu-utils`, `dosfstools` and `e2fsprogs`; if
a disk cannot be made, it stops before changing the binaries.

Updating from 0.6.5 or earlier, the update script tightens the modes of Sherpa's configuration
and log files, on every run, even when there is nothing to install. It sets `/opt/sherpa/config`,
`/opt/sherpa/env` and `/opt/sherpa/logs` to `750`, `sherpa.toml`, `sherpa.env` and
`sherpa.env.example` to `600`, and `sherpad.log` and its rotated copies to `640`, and makes
`sherpa` their owner. It changes no file's contents and leaves a symlink alone. Members of the
`sherpa` group can then no longer read `sherpa.toml` or `sherpa.env`: edit them with `sudoedit`
or `sudo -u sherpa`. Before, `sherpa.toml` got the umask of whoever ran `sherpad init`, often
`664`, so any account on the server could read it; treat any password you set in it as exposed.
Run `sherpad init` as `sherpa` from now on, `sudo -u sherpa -H sherpad init`. See
[file permissions](../install/automated.md#file-permissions).

Updating from 0.6.5 or earlier, `sherpa.toml` has a `[ztp_server]` table that `sherpad` no longer
has. Nothing ever read it; it does not set node credentials (see
[Node Credentials](../../architecture/credentials.md)). The file still loads: `sherpad` ignores
the table and logs a warning at each start until you delete it, with
`sudoedit /opt/sherpa/config/sherpa.toml`. The update script does not edit the file. If you set
a password there that you use elsewhere, treat it as exposed. `sherpad init` now refuses to run as
any account but `sherpa`, root included.

## Updating to 0.7.0

0.7.0 no longer converts what releases before 0.6.5 kept in each lab's directory on the server,
`/opt/sherpa/labs/<lab-id>/`. 0.6.4 and 0.6.5 did that every time `sherpad` started (see
[Updating to 0.6.4 and 0.6.5](#updating-to-064-and-065)). Before you update a server to 0.7.0:

1. **A server on 0.6.3 or earlier must update to 0.6.5 first, and start `sherpad` once.** The
   update script starts it:

    ```
    curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/v0.6.5/scripts/sherpa_update.sh | sudo bash -s -- --version v0.6.5
    ```

2. **Redeploy from the CLI, or destroy, every lab created before 0.6.4** whose nodes have not been
   redeployed from the CLI since: run `sherpa redeploy -n <node>` from the lab's folder for each
   node, or `sherpa destroy`. On 0.6.4 and 0.6.5 the web UI refuses to redeploy those nodes,
   with a message that the node "was imported from a saved manifest". 0.7.0 no longer tells
   them apart: a web UI redeploy of such a node rebuilds it **without its `ztp.config`,
   environment variables and provisioners**.

The update script does not check either step, and `sherpad` 0.7.0 starts all the same. On a
server that skipped 0.6.5 it ignores the files older releases left in the lab directories, which
stay there until the lab is destroyed, and their labs run without what they held: a lab has no
definition, so it runs with the defaults and the web UI refuses to redeploy it; its nodes' SSH
config logs in with the `sherpa` account instead of yours; and its Talos clusters have no plan,
so `sherpa down` powers their nodes off, `sherpa redeploy` refuses their workers and
`sherpa download` leaves them out. Destroy and recreate such a lab.

### Your login on nodes

0.7.0 gives every node Sherpa builds one login, yours. The shared `sherpa` account and its
published password, `Everest1953!`, are gone from new nodes. See
[Your Login on Nodes](../../architecture/personal-accounts.md).

- **Set a device password before the next `sherpa up` or `sherpa redeploy`.** Both refuse to
  start, before they create anything, for every user who has none, in the CLI and the web UI.
  Use `sherpa server user device-password` or the **Profile** page. See
  [Device Password](../../architecture/device-password.md). `resume`, `down`, `destroy` and
  `inspect` do not need it.
- **You log in as yourself.** A new node has no `sherpa` account. You log in with your Sherpa
  username and your keys, and the vendor accounts that have a fixed name, such as `admin` and
  `root`, take your device password. Cisco FTDv has only `admin`, with your device password.
- **Delete `provision_current_user` from your manifests.** The setting is removed, and a manifest
  that still sets it, to `true` or `false`, is refused by `sherpa validate`, `sherpa up` and
  `sherpa redeploy` with ``unknown field `provision_current_user` ``.
- **Labs built before 0.7.0 keep `sherpa`.** Their nodes keep the `sherpa` account, its published
  password and trust in the lab's old SSH key, and their SSH config keeps `User sherpa`, until
  each node is redeployed with `sherpa redeploy -n <node>` or the lab is recreated. `sherpad` logs
  one warning at every start while any such node remains. `sherpa download --force` writes an SSH
  config without the `IdentityFile` line, after which `sherpa ssh` asks for the old password; the
  old key stays in `.sherpa/ssh/key` for `ssh -i`.
- **The lab SSH key is gone.** `sherpa up` makes no key for a new lab, and `sherpa up` and
  `sherpa download` no longer write `.sherpa/ssh/key`: nodes take only your own keys. A key file
  from before 0.7.0 is left in the lab folder until `sherpa destroy` deletes `.sherpa/`, and the
  server deletes a lab's old key with the lab. MikroTik nodes no longer get `sherpa_ssh_key.pub`
  on their config disk.
- **Windows nodes have one enabled login, yours.** The image's built-in `Administrator` and the
  `Admin` account cloudbase-init creates are disabled at first boot. See
  [Windows Server](../../nodes/windows/windows-server.md#accounts).
- **Some models refuse some names.** A node that cannot take your username as a login stops
  `sherpa up` and `sherpa redeploy` before anything is created. Windows takes at most 20
  characters; Cisco NX-OS at most 28, starting with a letter or digit; Arista vEOS and cEOS must
  start with a letter or digit; PAN-OS and OpenBSD take at most 31. An account named `root`,
  `sherpa` or `admin` from an old release cannot start labs. See
  [Login Names](../../architecture/personal-accounts.md#login-names).
- **Update the CLI and the server together.** A 0.7.0 CLI and an older server, or the other way
  round, disagree on the manifest and on what a response carries.

### Aruba AOS-CX: key login only

New and redeployed AOS-CX nodes take no password. Their configuration, served over TFTP, has
your SSH keys and no password: SSH password login is off, and your account and `admin` are
locked with the encrypted form of a random password nobody knows. Log in with `sherpa ssh`.
Neither account logs in with a password, on the console either; for console access, log in by
SSH and set a password yourself. AOS-CX nodes built before 0.7.0 keep their old accounts until
redeployed. See [Aruba AOS-CX](../../nodes/aruba/aruba-aoscx.md#logins).

### The lab router's HTTP service

The lab router's HTTP service, on port 8080, serves only the files of the nodes that boot by
HTTP (SONiC), from its root: `http://<router>:8080/<file>`, no longer `/configs/<file>`. It no
longer serves the TFTP configurations or the DHCP leases. Labs created on 0.7.0 get this at
`sherpa up`. A lab created before 0.7.0 keeps its old router, which still serves both, until its
first VM redeploy recreates the router (DHCP, DNS, TFTP, HTTP and the lab's outside access pause
for a few seconds; addresses are kept), or until the lab is recreated.

### Image ZTP login settings removed

A node image no longer has a ZTP username, password or password-auth setting. Sherpa's node
configurations never used them. The update drops any values stored, the encrypted password
included; the images and their ZTP method are kept. `sherpa server image show`, the web UI's
image pages and editor, and the [image API](../../api-reference.md#node-images) no longer show
them. Update the CLI and the server to 0.7.0 together: a CLI and a server on different sides of
this change cannot read each other's image details.

### SONiC has 32 data interfaces

A `sonic_linux` node now has 32 data interfaces, `eth1` to `eth32`, one for each front-panel
port of the SONiC VM; it had 52. The update sets every `sonic_linux` image still at 52 to 32. An
image set to another count keeps it.

- **Manifests:** a link on `eth33` to `eth52` of a SONiC node is refused at `sherpa up`. Move it
  to an interface from `eth1` to `eth32`. Those interfaces never reached a switch port.
- **Running labs** keep their nodes' 52 interfaces until a node is redeployed.

See [SONiC](../../nodes/sonic/sonic-linux.md#front-panel-ports).

### Image commands take `--kind`

The image commands name a kind with `--kind <kind>`, `virtual_machine`, `container` or
`unikernel`, the values a manifest node's [`kind`](../../manifest.md#kind-string) takes.
`--virtual-machine`, `--container` and `--unikernel` are gone, and are refused as unknown
arguments.

| Before | 0.7.0 |
|---|---|
| `sherpa server image scan --container` | `sherpa server image scan --kind container` |
| `sherpa server image scan --container --model mysql_db --repo mysql` | `sherpa server image scan --kind container --model mysql_db --repo mysql` |
| `sherpa image list --unikernel` | `sherpa image list --kind unikernel` |
| `sherpa server image list --virtual-machine` | `sherpa server image list --kind virtual_machine` |

`show`, `import`, `pull`, `delete` and `set-default` take `--kind` too. Without it they use the
model's default kind, which is the only kind every model has, so a command without a kind flag
works as before. Update scripts that pass the old flags.

## Updating to 0.6.4 and 0.6.5

Updating from 0.6.3 or earlier, the first time `sherpad` starts after the update it records each existing lab's definition from
the manifest it saved in `/opt/sherpa/labs/<lab-id>/`, then **deletes those saved manifests**
(`manifest.toml`, and `manifest.json` from older releases). Nothing else in the lab's directory
is touched, and your own `manifest.toml` in the lab folder is never read by the server. A saved
manifest that cannot be imported, such as one in the shape before 0.6.0, is deleted too, and its
lab runs with the defaults; the database backup does not hold these files, so copy them first if
you want to keep them. See
[lab definitions](../../architecture/database.md#lab-definitions). A node that needs files or
`$VAR` values can no longer be redeployed from the web UI, and neither can any node of a lab
started before the update until it has been redeployed once with `sherpa redeploy -n <node>`;
see [redeploying from the web UI](../../command-reference.md#redeploying-from-the-web-ui).

Updating from 0.6.4 or earlier, `sherpad` also stops keeping each lab's `lab-info.toml`,
`sherpa_ssh_config` and `sherpa_known_hosts` in `/opt/sherpa/labs/<lab-id>/`. The first time it
starts after the update it records the node accounts from each lab's `lab-info.toml` in the
database, then **deletes those three files**, and nothing else in the lab's directory. From then
on it builds them from the database whenever `sherpa up`, `sherpa download` or the web UI gives
them to you, and they are the same as before, so `sherpa ssh`, `sherpa console` and older
clients work unchanged. A server-side `lab-info.toml` that cannot be read is deleted with the
other two after a warning in the `sherpad` log; that lab's nodes keep the accounts the database
already has, or the `sherpa` account. The lab folders on
your clients are not touched. See [lab files](../../architecture/storage.md#lab-files).

Updating from 0.6.4 or earlier, `sherpad` also stops keeping each Talos cluster's plan, the
`cluster.toml` in `/opt/sherpa/labs/<lab-id>/clusters/<cluster>/`. The first time it starts
after the update it records each cluster's endpoint, shared address and load balancer addresses
in the database, then **deletes that file**. The cluster's `secrets.toml`, `talosconfig` and
`kubeconfig` stay, and `sherpa down`, `sherpa redeploy` and `sherpa download` work as before. A
`cluster.toml` that cannot be read, or that names a cluster the lab no longer has, is deleted
after a warning in the `sherpad` log naming the lab; `sherpa down` then powers that cluster's
nodes off instead of shutting them down through Talos, `sherpa redeploy` refuses its workers,
and `sherpa download` leaves the cluster out.

## Updating to 0.6.0

0.6.0 is a breaking release. Before you update a server, do the following in this order:

1. A server older than 0.5.0 must update to 0.5.12 first, as described in
   [Updating to 0.5.0](#updating-to-050). 0.6.0 does not read the old SurrealDB database, and
   its install and update scripts refuse such a server.
2. [Destroy every lab created before 0.5.15](#destroy-labs-created-before-0515), with the
   release the server runs now.
3. [Update every manifest](#update-every-manifest) to the grouped node settings.
4. [Recreate long-lived labs](#recreate-long-lived-labs) with their updated manifests.
5. Update any script that reads image details: the [image API JSON](#image-api) is nested.
6. Scripts that handle a memory refusal can use its own codes: JSON-RPC `-32005`, HTTP
   `507 INSUFFICIENT_MEMORY` ([Not enough host memory](../../api-reference.md#not-enough-host-memory)),
   and `sherpa` exit status `75` ([exit status](../../command-reference.md#exit-status)).
7. Update the server, then [update the `sherpa` CLI](client.md) on every client to 0.6.0. The
   CLI must be updated with the server: an older CLI cannot read, for example, a 0.6.0 server's
   [image details](#image-api).

### Destroy labs created before 0.5.15

0.6.0 removes the server's shared SSH key, `/opt/sherpa/ssh/sherpa_ssh_key`. Labs created before
Sherpa 0.5.15 still log in to their nodes with it, and would lose SSH access, so **destroy every
lab created before 0.5.15 first**, with the release the server runs now:

```
sherpa destroy
```

in the lab's folder, or from the web UI. Labs created from 0.5.15 have their own lab SSH key and
keep running.

The update script checks before it installs anything. While such labs exist it stops, names
them, and starts the running release again:

```
[INFO] Checking that v0.6.0 can use the database...
Error: 1 lab(s) still log in to their nodes with the server's shared SSH key, which this release removes; their nodes would lose SSH access:
  abcd1234 (core, owned by alice)
Destroy them with the Sherpa release this server ran before ('sherpa destroy' in the lab's folder, or the web UI), then start this release again. The database is unchanged.
[ERROR] v0.6.0 cannot use this server's database; nothing was installed.
```

Destroy the labs it names and run the update again. Once 0.6.0 has started, the script deletes
the server's key pair and its `/opt/sherpa/ssh` folder. A 0.6.0 `sherpad` installed some other
way refuses to start with the same message, and changes nothing; check a server before
installing by hand with the new binary's `sherpad check-database`, run as the `sherpa` user while
`sherpad` is stopped.

### Update every manifest

A node's settings move into groups such as `[nodes.cpu]` and `[nodes.ready_check]`, and
`[nodes.performance_tuning]` is gone: its settings are now in `cpu`, `numa`, `boot_disk` and
`interfaces`. A manifest with an old key is refused with an `unknown field` error that names it.
The table of old and new keys is in
[Upgrading manifests from flat keys](../../manifest.md#upgrading-manifests-from-flat-keys).
Sherpa also refuses a setting the node's kind does not take, such as `vm.watchdog` on a
container; see [Which node kinds take which settings](../../manifest.md#which-node-kinds-take-which-settings).

### Recreate long-lived labs

Labs created before the update keep running. `sherpa resume` of such a lab uses the default
readiness settings, because the lab's saved manifest has the old keys; destroy and recreate it
with an updated manifest to use its own.

### Image API

An image's JSON (`sherpa server --output json image show`, `GET /api/v1/images/...` and the
OpenAPI schema) nests its settings by group, in place of the flat fields. The table of old and
new fields is in the [API reference](../../api-reference.md#node-images). The
`sherpa server image show` table names its rows by the same keys.

## Updating to 0.5.30

A node image now has one [ZTP setting](../../architecture/zero-touch-provisioning.md#the-ztp-setting),
`ztp`, in place of the "enable" switch and the method beside it. The update converts every image:

- an image with ZTP switched off becomes `disabled`;
- a virtual machine image keeps its method. One stored with a method its model does not take,
  on which `sherpa up` failed, gets its model's default method;
- Arista cEOS, Nokia SR Linux, Juniper cEvolved and FRR container images become `volume`;
- every other container image, and every unikernel image, becomes `disabled`. These nodes start
  as they did before.

If you had switched ZTP off on a cEOS, SR Linux, cEvolved or FRR image, its nodes now start
without Sherpa's configuration, without a management address and without your login the
next time they are created or redeployed. Before, switching it off only left out the lab owner's account.

A manifest that sets `ztp_config` (now [`ztp.config`](../../manifest.md#ztp-object)) on a node that cannot
use it is now refused before the lab is created, where the file was ignored before: on an
application container other than Vault, and on any node whose ZTP is `disabled`.

In the API, an image's `ztp_enable` and `ztp_method` fields are replaced by `ztp`, one of
`disabled`, `cloud-init`, `cdrom`, `disk`, `http`, `ignition`, `nocloud`, `tftp`, `usb` and
`volume`. Scripts that read the old fields need changing. [Update the `sherpa` CLI](client.md) on every
client together with the server: an older CLI cannot read image details from a 0.5.30 server, and a
0.5.30 CLI cannot read them from an older server.

## Updating to 0.5.27

`sherpa up` exits with an error when the lab is only partly created: a container exited right
after it started, or a Kubernetes cluster, Vault or Keycloak did not come up. Before 0.5.27 these
were warnings and `sherpa up` exited with status 0. Scripts that run `sherpa up` now see a
non-zero status for such a lab; the lab is still created, so it can be used as it is or
destroyed. A node that is only slow to become ready is still a warning.

Labs have a [phase](../../command-reference.md#lab-phases) besides their status: `creating`,
`ready`, `destroying`, `destroy failed` or `interrupted`. The update makes every existing lab
`ready`. Only a `ready` lab can be stopped, resumed or redeployed; the others can only be
destroyed. A second `sherpa up` of a lab that exists, or that is being created, is refused
before it does anything, and no longer removes the other lab.

When the server starts, a lab it was creating when it stopped becomes `interrupted`, a lab it
was destroying becomes `destroy failed`, and a node it was building becomes `failed`. Nothing
is removed; destroy or redeploy them.

The CLI and the server can be updated separately: an older CLI does not show the phase, and an
older server's labs are shown as `ready`.

## Updating to 0.5.25

Node states change. A node being created is now `building` rather than `stopped`, a node whose
virtual machine or container no longer exists is `missing`, and the `created` state is gone:
nodes recorded `created` become `stopped`. See [node states](../../command-reference.md#node-states).

[Update the `sherpa` CLI](client.md) on every client together with the server. The server does not refuse an
older client, which only warns that the versions differ, but a CLI older than 0.5.25 cannot read
the new states: `sherpa inspect`, `sherpa destroy` and the other commands that read a lab's
details from the server fail with a decode error for a lab that has a `building` or `missing`
node. From 0.5.25 the CLI shows any state it does not know as `unknown`, so later new states do
not break it. The web UI is part of the server and needs no update.

## Updating to 0.5.23

Logins become server-side sessions, so that logging out, changing a password and deleting a user
end them at once. Tokens issued before 0.5.23 name no session, so after the update every user
must log in again: run `sherpa login` on each client, and log in again in the web UI.

From 0.5.23, `sherpad` refuses to start when its JWT secret file is damaged, instead of replacing
it; see
[Troubleshooting](../../help/troubleshooting.md#sherpad-does-not-start-the-jwt-secret-is-the-wrong-length).

## Updating to 0.5.0

Releases before 0.5.0 kept Sherpa's data in a SurrealDB container named `sherpa-db`. From 0.5.0,
`sherpad` keeps it in an embedded database file, `/opt/sherpa/db/sherpa.sqlite`. Only releases
0.5.0 to 0.5.12 can move the data across, so a 0.4.x server must update to 0.5.12 first, with the
0.5.12 update script, and then to the release you want:

```
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/v0.5.12/scripts/sherpa_update.sh | sudo bash -s -- --version v0.5.12
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh | sudo bash
```

The current update script refuses a server whose data is still in SurrealDB, and changes nothing.
The install script refuses any server that still has the `sherpa-db` container. Once the server
works on 0.5.12 or later, remove the old container and its data: `sudo docker rm sherpa-db` and
`sudo rm -rf /opt/sherpa/db/sherpa.db`.
