# SSH

The `ssh` provisioner copies files and runs scripts on Linux and BSD virtual machines. Once a
node is ready, the `sherpa` CLI on your machine connects to it over SSH, through the Sherpa
server as a jump host. The server only forwards the encrypted SSH connection, so it never sees or
stores the contents.

## Example

```toml
name = "dev"
provision_current_user = true

[[nodes]]
name = "dev01"
model = "ubuntu_linux"

[[nodes.provisioners]]
type = "ssh"
env_files = ["secrets/dev.env"]
scripts = ["secrets/setup.sh"]

[[nodes.provisioners.files]]
src = "~/.config/gh/hosts.yml"
dst = "~/.config/gh/hosts.yml"
mode = 600
```

With `secrets/dev.env` holding `KEY=value` lines:

```sh
GH_TOKEN=$GH_TOKEN
ANTHROPIC_API_KEY='sk-example'
```

A value that is exactly one variable reference, `KEY=$NAME` or `KEY=${NAME}`, is replaced with
that variable's value from the environment you run `sherpa` in, as in the manifest's
`environment_variables`. Here `GH_TOKEN` is copied from your shell, so the token does not have
to be written in the file. If the variable is not set, provisioning stops before anything on
the node changes. Other lines are copied as written, so a value such as `$HOME/bin:$PATH` is
still expanded by the node's shell when it loads the file.

See [`provisioners`](../../manifest.md#provisioners-listobject) in the manifest reference for
every field.

## What It Does

Everything runs as the node's login user: your [personal account](../personal-accounts.md) when
`provision_current_user` is enabled, otherwise the `sherpa` user. In order:

1. **Waits for the node.** It retries the login until the account exists, then waits for
   cloud-init to finish first-boot work, so your files are not overwritten by it. Every step
   on the node then uses that one connection.
2. **Copies `files`** over SFTP. Missing parent directories are created, private to the user.
   Each file is made private before its contents arrive, then given its `mode` (default `600`).
3. **Copies `env_files`** into `~/.env.d/`, mode `600`, with `$NAME` values replaced from
   your environment and quoted for the shell, and adds a line to `~/.bash_profile`, or
   to `~/.profile` when there is no `~/.bash_profile`, that loads every file in `~/.env.d/` in
   login shells, exporting its variables.
4. **Runs `scripts`.** The script is sent through the SSH session's input, never on a command
   line, and runs through its shebang line in a login shell, as when you log in: the login
   files (`/etc/profile`, `/etc/profile.d/`, and `~/.bash_profile` or `~/.profile`) run first,
   so tools they put on your `PATH`, such as mise or Cargo, are found. On FreeBSD, whose `sh`
   has no login option, `/etc/profile` and `~/.profile` are read instead, so anything
   `~/.profile` prints at login, such as FreeBSD's `fortune` tip, shows in the output. It then gets the
   variables from the manifest's `environment_variables` and from `~/.env.d/`, which take
   priority over the login files. A script that exits with an error stops the node's remaining
   steps.

## Several Nodes at Once

Nodes are provisioned at the same time, up to 8 at once by default. Each node starts as soon
as there is room: it does not wait for the others to be ready or finish. Set
[`provision_concurrency`](../../manifest.md#provision_concurrency-int) to change the limit, for
example to `1` to provision one node at a time.

Every line of output starts with the node's name, so the lines of nodes running at once can be
told apart, and each node ends with a `provisioned` or `failed` line:

```
alpine01 | provisioning alpine01.a7343ce5
alpine02 | provisioning alpine02.a7343ce5
alpine01 | copying files/note.txt to ~/note.txt
alpine01 | running files/setup.sh
alpine02 | running files/setup.sh
alpine02 | provisioned
alpine01 | provisioned
```

A node that fails does not stop the others. The table at the end lists every node in manifest
order.

## When It Runs

- **`sherpa up`**: after the lab is created, on every node that came up with SSH. A node that
  was not ready is reported as skipped.
- **`sherpa redeploy`**: on the redeployed node, once it is back.
- **`sherpa provision`**: on demand. Running it again replaces the files and does not add the
  loader line twice.

## Requirements

- Run the command from the lab's folder, where `sherpa up` wrote `sherpa_ssh_config`.
- Nothing extra on your machine: the `sherpa` CLI has its own SSH client. No `ssh` or `scp`
  program is used.
- A login to the Sherpa server as the jump host. If your key has a passphrase or the server
  needs your password, you are asked once, even when nodes are provisioned at the same time,
  and the answer is used for the other nodes. A key loaded in your SSH agent needs no prompt. See
  [SSH](../ssh.md#jumphost).
- Linux and BSD virtual machines only: the `cloud-init` Linux and BSD models, Alpine and
  Flatcar.

## Limits

- **As the login user.** Files can only go where the login user can write. Use a script with
  `sudo`, or `doas` on Alpine and OpenBSD, for anything else.
- Removing a file from the manifest does not remove it from the node.
