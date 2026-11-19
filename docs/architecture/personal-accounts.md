# Your Login on Nodes

You log in to lab nodes as yourself: your Sherpa username, your own SSH keys, your
[device password](device-password.md) and administrator rights. It is the only login Sherpa
creates. There is no `sherpa` account and no shared password.

There is nothing to enable. Every node whose configuration Sherpa generates gets your login.

## Before You Start

Your Sherpa user needs two things before `sherpa up` or `sherpa redeploy` will start a lab:

- At least one SSH public key registered. See [SSH Keys](ssh-keys.md) to generate and register
  one. Keep the matching private keys on your workstation or in your SSH agent. They are never
  sent to the server.
- A [device password](device-password.md): `sherpa server user device-password`, or the
  **Profile** page of the web UI. It is the password of your login on every node.

Both checks run before anything is created, for every lab. `resume`, `down`, `destroy` and
`inspect` need neither.

## What You Get

### Linux and BSD

Each Linux and BSD VM gets an account with:

- Your Sherpa username
- A home directory at `/home/<username>` and the Bash shell
- Your registered public keys as authorized keys
- Your device password as its password
- Passwordless `sudo`

Alpine keeps its own tools: your account gets the `ash` shell (`/bin/sh`) and passwordless
`doas` instead of Bash and `sudo`. Install `bash` or `sudo` yourself if you want them, for
example with a `startup_scripts` entry that runs `apk add bash sudo`.

On NixOS your account gets Bash from the system profile, `/run/current-system/sw/bin/bash`,
because NixOS has no `/bin/bash`, and passwordless `sudo` through the `wheel` group.

FreeBSD and OpenBSD also keep their own tools: your account gets the `sh` shell and joins the
`wheel` group. On OpenBSD, admin rights use `doas`, part of the base system, which lets `wheel`
run commands as root without a password. On FreeBSD they use passwordless `sudo`, which the
image includes.

On Flatcar your account joins the `wheel` and `docker` groups and has passwordless `sudo`. It
also gets any keys the manifest sets in `ssh.authorized_keys` or `ssh.authorized_key_files`.

Manifest `user_scripts` run as your account, and manifest `environment_variables` are set in
your account's login shells.

`generic` virtual machine nodes are set up as a Linux VM that uses `cloud-init`.

### Windows

Windows VMs get a local administrator account with your username, your device password and your
keys. Each account has its own keys file, `C:\ProgramData\ssh\authorized_keys\<username>`, so
your keys log in only as you. Yours is the only enabled account: at first boot Sherpa disables
every other, such as the image's built-in `Administrator` and the `Admin` account cloudbase-init
creates. See [Windows Server](../nodes/windows/windows-server.md#accounts).

### Network Devices

Network devices get an administrator account with your username, your keys and your device
password. Fixed vendor accounts take your device password too: `admin` on NX-OS, IOS XR,
PAN-OS, SR Linux (`admin-user`) and RouterOS, `root` on Junos, and the ASA enable password.
Aruba AOS-CX is the exception: you log in by key only, and `admin` is locked (see
[Aruba AOS-CX](#aruba-aos-cx)).

| Models | Admin rights | Key types | Keys used |
|---|---|---|---|
| `cisco_ios`, `cisco_iosl2`, `cisco_iol`, `cisco_ioll2`, `cisco_csr1000`, `cisco_cat8000`, `cisco_cat9000` | privilege 15 | RSA | first 2 |
| `cisco_iosxr9000` | `root-lr` and `netadmin` groups | RSA | first 4 |
| `cisco_asa` | privilege 15 | Ed25519, ECDSA, RSA | first 1 |
| `cisco_nexus9300` | `network-admin` | ECDSA, RSA | first 1 |
| `arista_eos` | privilege 15 | Ed25519, ECDSA, RSA | first 2 |
| `aruba_aoscx` | `administrators` | Ed25519, ECDSA, RSA | first 32 |
| `juniper_router`, `juniper_switch`, `juniper_srxv3`, `juniper_evolved` | `super-user` | Ed25519, ECDSA, RSA | all |
| `nokia_srlinux` | superuser role | Ed25519, ECDSA, RSA | first 32 |
| `paloalto_panos` | superuser | Ed25519, RSA | first 1 |
| `mikrotik_chr` | `full` group | Ed25519, RSA | all |
| `cumulus_linux` | `system-admin` | Ed25519, ECDSA, RSA | all |
| `sonic_linux`, `frr_linux` | passwordless `sudo` | all | all |

Keys of a type a device does not take, and keys past its limit, are left out, and `sherpa up`
lists them. If none of your keys fits a node, `sherpa up` stops before it creates anything and
shows the command that makes a key of the right type. RSA is the only type every device takes;
see [SSH Keys](ssh-keys.md#which-key-type).

Cisco ISE has a single administrator, which is you: your username, your device password and
your first RSA key.

### Aruba AOS-CX

AOS-CX gets no password, because its configuration is served over TFTP and AOS-CX has no hashed
password form Sherpa can write. Your account has your keys and no usable password, and SSH
password login is turned off:

- **You log in by SSH key only.** `sherpa ssh` works as on any node. A password, empty or not,
  is refused over SSH, on the console and on the HTTPS REST API.
- **`admin` is locked.** AOS-CX ships `admin` with an empty password and does not let it be
  deleted, so Sherpa sets it, and your account, to the encrypted form of a random password that
  nobody knows. Neither account can log in with a password, on the console either.
- **`sherpa console` gives you the login prompt, but no account to log in with.** If you need
  console access, log in by SSH first and set a password yourself
  (`user <username> password`).

Your device password is still required to start a lab, as for every lab, but it is not used on
AOS-CX nodes. USB ZTP, which would keep the configuration off the network, is tracked in
[#690](https://github.com/bwks/sherpa/issues/690).

### Cisco FTDv

FTDv takes no account at boot. Its only login is `admin`, with your device password and no SSH
key.

### Not Changed

Talos, application containers such as databases and Git servers, and unikernels have no way to
add an account at boot, so Sherpa creates no login on them.

Two application containers have an administrator of their own, which Sherpa sets: Keycloak's
`admin` and SurrealDB's `root`. Each node gets its own, with a random password generated when the
node is created and kept when it is redeployed; it is not your device password, and no two nodes
share one. `sherpa up` and `sherpa download` write them to your lab folder, for you only. See
[Keycloak](../nodes/keycloak/keycloak-server.md#node-access) and
[SurrealDB](../nodes/sql/surrealdb.md#root-user).

!!! note
    A node with a custom `ztp.config` gets no login, because your config replaces the one the
    account would be written into. `sherpa up` says which nodes this applies to.

## Passwords on Nodes

Sherpa writes your device password into each node's configuration in the form the device takes.
Linux, NixOS, Alpine, FreeBSD, Flatcar, Arista, Junos, FRR, SONiC and PAN-OS get a salted hash.
The others take plain text, because the device needs it or hashes it itself. Where the
configuration is served over the lab network (TFTP and HTTP), it carries only a hash. Aruba
AOS-CX, which has no hash form, gets no password at all.

| Models | Login | Password in the configuration | Delivered by |
|---|---|---|---|
| Ubuntu, Alma, Rocky, CentOS, Fedora, openSUSE, RHEL, SUSE, Kali, Omarchy, `devbox_linux`, `generic` virtual machines, Infrahub, Jenkins, Nautobot, NetBox, SigNoz, `virt_server` | you, `sudo` | SHA-512 hash | cloud-init CD-ROM |
| NixOS | you, `wheel` | SHA-512 hash | cloud-init CD-ROM |
| Alpine | you, `wheel` and `doas` | SHA-512 hash | cloud-init CD-ROM |
| FreeBSD | you, `wheel` and `sudo` | SHA-512 hash | cloud-init CD-ROM |
| OpenBSD | you, `wheel` and `doas` | plain text to cloud-init, which hashes it on the node | cloud-init CD-ROM |
| Windows Server, `devbox_windows` | you, local Administrator | plain text (cloudbase-init needs it) | cloudbase-init CD-ROM |
| Flatcar | you, `wheel` and `docker` | SHA-512 hash | Ignition |
| Arista vEOS | you | SHA-512 hash | TFTP |
| Arista cEOS | you | SHA-512 hash | container volume |
| Aruba AOS-CX | you, by key only; `admin` locked | none: no password login | TFTP |
| Cisco IOSv, IOSvL2 | you | plain text | config disk |
| Cisco IOL, IOL-L2 | you | plain text | container volume |
| Cisco CSR1000v, Cat8000v, Cat9000v | you | plain text | CD-ROM |
| Cisco ASAv | you, enable password | plain text | CD-ROM |
| Cisco Nexus 9300v | you, `admin` | plain text | CD-ROM |
| Cisco IOS XRv 9000 | you, `admin` | plain text | CD-ROM |
| Cisco ISE | you, the only administrator | plain text | disk |
| Cisco FTDv | `admin` | plain text | CD-ROM |
| Juniper vSRX3, vRouter, vSwitch, vEvolved, cEvolved | you, `root` | SHA-512 hash | CD-ROM (vSRX3, vRouter, vSwitch), TFTP or USB (vEvolved), container volume (cEvolved) |
| Nokia SR Linux | you, `admin-user` | plain text; SR Linux hashes it on commit | container volume |
| Palo Alto PAN-OS | you, `admin` | SHA-256 hash | bootstrap CD-ROM |
| MikroTik CHR | you, `admin` | plain text | config disk |
| FRR | you, `sudo` | SHA-512 hash | container volume |
| Cumulus | you | plain text | USB disk |
| SONiC VM | you, `sudo` | SHA-512 hash | HTTP |
| SONiC container | you, `sudo` (when the image has `sudo`), `frrvty` | SHA-512 hash | container volume |

A configuration delivered on a disk, CD-ROM, USB disk or container volume is not served on the
network. See [Who Can Read a Node's Configuration](zero-touch-provisioning.md#who-can-read-a-nodes-configuration).

A new device password applies to nodes you create or redeploy afterwards. Running nodes keep the
one they started with.

### Login Names

Your Sherpa username is your login name, and most models take any username. A few take fewer
characters or a narrower start. `sherpa up` and `sherpa redeploy` refuse, before they create or
remove anything, a lab with a node that cannot take your name. Sherpa never shortens or changes
it. Start the lab from an account with a name the node takes.

| Models | Limit |
|---|---|
| Windows Server, `devbox_windows` | at most 20 characters |
| `cisco_nexus9300` | at most 28 characters, and a letter or digit first |
| `arista_eos` | a letter or digit first (not `_`) |
| `paloalto_panos` | at most 31 characters |
| `open_bsd` | at most 31 characters |

An older account named like a reserved login (`root`, `sherpa`, `admin`) cannot start labs at
all.

## Connect

`sherpa ssh <node-name>` uses your username automatically. You can also connect with any SSH
client using the lab's generated [SSH config](ssh.md), with your SSH agent or default keys.
Where the node takes a password, log in with your device password.

## Key Changes and Redeploy

Keys and the device password are applied when the node is created. Changing your registered keys
or your device password does not update a running node. Use `sherpa redeploy` to apply them,
which rebuilds the node with your current keys and password.

Only the lab owner can redeploy, even if an administrator asks. Likewise only the owner can
download the lab's files or connect to its nodes: an administrator can manage another user's lab
but is not given the SSH config, host keys, credentials, console or VNC console. An administrator
can still reset a user's Sherpa password and sign in as them; that is logged and ends the user's
sessions. See [Overview](overview.md). After a redeploy the CLI
downloads the refreshed SSH configuration for you. If you redeploy from another client or the
web UI, run this from your local lab directory:

```bash
sherpa download <lab-id> --force
```

`sherpa resume` keeps the account, its keys and its password.
