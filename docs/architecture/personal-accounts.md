# Personal Accounts

By default, you log in to lab nodes as the generated `sherpa` user. Personal accounts let you
log in as yourself instead, with your own SSH keys and administrator rights.

## Enable

Set `provision_current_user` at the top of the manifest. It defaults to `false`.

```toml
name = "personal-lab"
provision_current_user = true

[[nodes]]
name = "vm"
model = "ubuntu_linux"
```

## Before You Start

Your Sherpa user needs at least one SSH public key registered; every lab needs one, whether or
not it uses personal accounts. See [SSH Keys](ssh-keys.md) to generate and register a key.

Keep the matching private keys on your workstation or in your SSH agent. They are never
sent to the server.

## What You Get

### Linux and BSD

Each Linux and BSD VM gets an account with:

- Your Sherpa username
- A home directory at `/home/<username>` and the Bash shell
- Your registered public keys as authorized keys
- Passwordless `sudo`

Alpine keeps its own tools: your account gets the `ash` shell (`/bin/sh`) and passwordless
`doas` instead of Bash and `sudo`. Install `bash` or `sudo` yourself if you want them, for
example with a `startup_scripts` entry that runs `apk add bash sudo`.

On NixOS your account gets Bash from the system profile, `/run/current-system/sw/bin/bash`,
because NixOS has no `/bin/bash`, and passwordless `sudo` through the `wheel` group.

FreeBSD and OpenBSD also keep their own tools: your account gets the `sh` shell and joins the
`wheel` group. On OpenBSD, admin rights use `doas`, part of the base system, which lets `wheel`
run commands as root without a password. On FreeBSD they use passwordless `sudo`, which the
image includes. The `sherpa` account is set up the same way.

No password is copied into the VM. The `sherpa` account is still created as usual.

Manifest `user_scripts` run as your account instead of `sherpa`, and manifest
`environment_variables` are set in your account's login shells instead of the `sherpa`
user's.

`generic_vm` nodes are set up as a Linux VM that uses `cloud-init`.

### Windows

Windows VMs get a local administrator account with your username and your keys. Each account
has its own keys file, `C:\ProgramData\ssh\authorized_keys\<username>`, so your keys log in
only as you, and the `sherpa` key only as `sherpa`. The account has a random password that is
never shown; log in with your key.

### Network Devices

Network devices get an administrator account with your username next to the `sherpa` account.
You log in with your key. Where the device needs a password, the account gets a random one that
is never shown.

| Models | Admin rights | Key types | Keys used |
|---|---|---|---|
| `cisco_iosv`, `cisco_iosvl2`, `cisco_csr1000v`, `cisco_cat8000v`, `cisco_cat9000v` | privilege 15 | RSA | first 2 |
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

Cisco ISE has a single administrator, `sherpa`, which takes one key. With personal accounts it
takes your first RSA key instead of the server's, so you log in to ISE as `sherpa` with your own
key.

### Not Changed

Cisco FTDv, Talos, application containers such as databases and Git servers, and unikernels
have no way to add an account at boot. They keep their usual login.

!!! note
    A node with a custom `ztp_config` gets no personal account, because your config replaces
    the one the account would be written into. `sherpa up` says which nodes this applies to.

### Username Rules

Your Sherpa username is used as the login name, so it already meets the rules for one. See
[`sherpa server user create`](../command-reference.md#sherpa-server-user-create) for the
username rules.

If you have no valid keys registered, `sherpa up` stops before it creates anything.

## Connect

`sherpa ssh <node-name>` uses your username automatically. You can also connect with any SSH
client using the lab's generated [SSH config](ssh.md), with your SSH agent or default keys.

## Key Changes and Redeploy

Keys are applied when the VM is created. Changing your registered keys does not update a
running VM. Use `sherpa redeploy` to apply them, which rebuilds the VM with your current keys.

Only the lab owner can redeploy, even if an administrator asks. After a redeploy the CLI
downloads the refreshed SSH configuration for you. If you redeploy from another client or the
web UI, run this from your local lab directory:

```bash
sherpa download <lab-id> --force
```

`sherpa resume` keeps the account and its keys.
