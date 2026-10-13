# Personal Accounts

By default, you log in to lab VMs as the generated `sherpa` user. Personal accounts let you
log in as yourself instead, with your own SSH keys and passwordless sudo.

## Enable

Set `provision_current_user` at the top of the manifest. It defaults to `false`.

```toml
name = "personal-lab"
provision_current_user = true

nodes = [
  { name = "vm", model = "ubuntu_linux" },
]
```

## Before You Start

Your Sherpa user needs at least one SSH public key registered. Add keys on the **Profile**
page of the web UI. An administrator can also set keys when creating a user with the
`--ssh-key` option of `sherpa server user create`.

Keep the matching private keys on your workstation or in your SSH agent. They are never
sent to the server.

## What You Get

Each supported VM gets an account with:

- Your Sherpa username
- A home directory at `/home/<username>` and the Bash shell
- Your registered public keys as authorized keys
- Passwordless `sudo`

No password is copied into the VM. The `sherpa` account is still created as usual.

Personal accounts apply to Linux VMs that use `cloud-init`, and to Flatcar. Windows, BSD,
containers, unikernels and network devices are not changed.

!!! note
    A node with a custom `ztp_config` cannot use this setting.

### Username Rules

Your username must:

- be at most 32 characters
- start with a lowercase letter or underscore
- contain only lowercase letters, digits, underscores and hyphens
- not be `root` or `sherpa`

If the username is invalid, or you have no valid keys registered, `sherpa up` stops before it
creates anything.

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
