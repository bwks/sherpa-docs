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

`generic_vm` nodes are set up as a Linux VM that uses `cloud-init`.

### Windows

Windows VMs get a local administrator account with your username, your device password and your
keys. Each account has its own keys file, `C:\ProgramData\ssh\authorized_keys\<username>`, so
your keys log in only as you.

### Network Devices

Network devices get an administrator account with your username, your keys and your device
password. Fixed vendor accounts take your device password too: `admin` on NX-OS, IOS XR,
AOS-CX, PAN-OS, SR Linux (`admin-user`) and RouterOS, `root` on Junos, and the ASA enable
password.

| Models | Admin rights | Key types | Keys used |
|---|---|---|---|
| `cisco_iosv`, `cisco_iosvl2`, `cisco_iol`, `cisco_ioll2`, `cisco_csr1000v`, `cisco_cat8000v`, `cisco_cat9000v` | privilege 15 | RSA | first 2 |
| `cisco_iosxrv9000` | `root-lr` and `netadmin` groups | RSA | first 4 |
| `cisco_asav` | privilege 15 | Ed25519, ECDSA, RSA | first 1 |
| `cisco_nexus9300v` | `network-admin` | ECDSA, RSA | first 1 |
| `arista_veos`, `arista_ceos` | privilege 15 | Ed25519, ECDSA, RSA | first 2 |
| `aruba_aoscx` | `administrators` | Ed25519, ECDSA, RSA | first 32 |
| `juniper_vrouter`, `juniper_vswitch`, `juniper_vsrxv3`, `juniper_vevolved`, `juniper_cevolved` | `super-user` | Ed25519, ECDSA, RSA | all |
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

### Cisco FTDv

FTDv takes no account at boot. Its only login is `admin`, with your device password and no SSH
key.

### Not Changed

Talos, application containers such as databases and Git servers, and unikernels have no way to
add an account at boot, so Sherpa creates no login on them.

!!! note
    A node with a custom `ztp.config` gets no login, because your config replaces the one the
    account would be written into. `sherpa up` says which nodes this applies to.

## Passwords on Nodes

Sherpa writes your device password into each node's configuration in the form the device takes.
Linux, NixOS, Alpine, FreeBSD, Flatcar, Arista, Junos, FRR, SONiC and PAN-OS get a salted hash.
The others take plain text, because the device needs it or hashes it itself. Where the
configuration is served over the lab network (TFTP and HTTP), it carries only a hash, except on
Aruba AOS-CX, which is plain text on TFTP until Sherpa hashes it
([#676](https://github.com/bwks/sherpa/issues/676)).

| Models | Login | Password in the configuration | Delivered by |
|---|---|---|---|
| Ubuntu, Alma, Rocky, CentOS, Fedora, openSUSE, RHEL, SUSE, Kali, Omarchy, `devbox_linux`, `generic_vm`, Infrahub, Jenkins, Nautobot, NetBox, SigNoz, `virt_server` | you, `sudo` | SHA-512 hash | cloud-init CD-ROM |
| NixOS | you, `wheel` | SHA-512 hash | cloud-init CD-ROM |
| Alpine | you, `wheel` and `doas` | SHA-512 hash | cloud-init CD-ROM |
| FreeBSD | you, `wheel` and `sudo` | SHA-512 hash | cloud-init CD-ROM |
| OpenBSD | you, `wheel` and `doas` | plain text to cloud-init, which hashes it on the node | cloud-init CD-ROM |
| Windows Server, `devbox_windows` | you, local Administrator | plain text (cloudbase-init needs it) | cloudbase-init CD-ROM |
| Flatcar | you, `wheel` and `docker` | SHA-512 hash | Ignition |
| Arista vEOS | you | SHA-512 hash | TFTP |
| Arista cEOS | you | SHA-512 hash | container volume |
| Aruba AOS-CX | you, `admin` | plain text | TFTP |
| Cisco IOSv, IOSvL2 | you | plain text | config disk |
| Cisco IOL, IOL-L2 | you | plain text | container volume |
| Cisco CSR1000v, Cat8000v, Cat9000v | you | plain text | CD-ROM |
| Cisco ASAv | you, enable password | plain text | CD-ROM |
| Cisco Nexus 9300v | you, `admin` | plain text | CD-ROM |
| Cisco IOS XRv 9000 | you, `admin` | plain text | CD-ROM |
| Cisco ISE | you, the only administrator | plain text | disk |
| Cisco FTDv | `admin` | plain text | CD-ROM |
| Juniper vSRX3, vRouter, vSwitch, vEvolved, cEvolved | you, `root` | SHA-512 hash | TFTP (vSRX3, vEvolved), CD-ROM, USB (vEvolved), container volume (cEvolved) |
| Nokia SR Linux | you, `admin-user` | plain text; SR Linux hashes it on commit | container volume |
| Palo Alto PAN-OS | you, `admin` | SHA-256 hash | bootstrap CD-ROM |
| MikroTik CHR | you, `admin` | plain text | config disk |
| FRR | you, `sudo` | SHA-512 hash | container volume |
| Cumulus | you | plain text | USB disk |
| SONiC | you, `sudo` | SHA-512 hash | HTTP |

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
| `cisco_nexus9300v` | at most 28 characters, and a letter or digit first |
| `arista_veos`, `arista_ceos` | a letter or digit first (not `_`) |
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

Only the lab owner can redeploy, even if an administrator asks. After a redeploy the CLI
downloads the refreshed SSH configuration for you. If you redeploy from another client or the
web UI, run this from your local lab directory:

```bash
sherpa download <lab-id> --force
```

`sherpa resume` keeps the account, its keys and its password.
