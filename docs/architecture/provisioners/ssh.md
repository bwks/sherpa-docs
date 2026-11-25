# SSH

The `ssh` provisioner copies files and runs scripts on the Linux and BSD virtual machines
listed under [Requirements](#requirements). Once a
node is ready, the `sherpa` CLI on your machine connects to it over SSH, directly, or with
`--ssh-jump` through the Sherpa server as a jump host. The server never sees or stores the
contents: with the jump it only forwards the encrypted SSH connection.

## Example

```toml
name = "dev"

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
# Copied from your shell, so the token is not written in the file.
GH_TOKEN=${GH_TOKEN}
API_URL=https://${API_HOST}:8443
DB_PASSWORD=\$ecret
EDITOR=vim
```

## Variables From Your Environment

An env file is data, not a shell script. Each line is `KEY=value`, optionally after `export` or
indented, a comment starting with `#`, or blank; any other line is refused. A value may be in
one pair of single or double quotes, which are not part of it. Its values follow the one rule
the manifest's [`environment_variables`](../../manifest.md#environment_variables-liststring)
follow:

- `${NAME}`, the whole value or part of it, is replaced with the variable `NAME` from the
  environment you run `sherpa` in.
- `\$` is a literal `$`: above, `DB_PASSWORD` is `$ecret` on the node.
- Any other `$`, such as `$NAME`, `$HOME/bin:$PATH`, `$1` or a lone `$`, is refused, naming the
  file, the line and the key, and saying to write `${NAME}` or `\$`.

Each value reaches the node quoted, so the node's shell expands nothing in it. Use a script for
anything that needs the node's shell, such as adding to `PATH`.

A variable that is not set, or a `$` the rule refuses, stops provisioning before anything on the
node changes: the error names the file, the line and the key, never a value.

See [`provisioners`](../../manifest.md#provisioners-listobject) in the manifest reference for
every field.

## What It Does

Everything runs as the node's login user: [your login](../personal-accounts.md). In order:

1. **Reads your files.** Every file, env file and script of every `ssh` provisioner on the
   node is read from your machine, and every env file value is resolved. A
   missing file, an unset variable or a refused `$` fails the node before it is connected to, so nothing on
   the node changes, even when the problem is in its second provisioner.
2. **Waits for the node.** It retries the login until the account exists, then waits for
   cloud-init to finish first-boot work, so your files are not overwritten by it. The login and
   the cloud-init wait share the lab's [`ready_timeout`](../../manifest.md#ready_timeout-int),
   600 seconds by default: a node that has not finished both when it runs out is reported
   failed, and the next node starts in its place. Every step on the node then uses that one
   connection.
3. **Copies `files`** over SFTP. Missing parent directories are created, private to the user.
   Each file is made private before its contents arrive, then given its `mode` (default `600`).
4. **Copies `env_files`** into `~/.env.d/`, mode `600`, with their values resolved as in
   [Variables From Your Environment](#variables-from-your-environment) and quoted for the
   shell, and adds a line to `~/.bash_profile`, or
   to `~/.profile` when there is no `~/.bash_profile`, that loads every file in `~/.env.d/` in
   login shells, exporting its variables.
5. **Runs `scripts`.** The script is sent through the SSH session's input, never on a command
   line, and runs through its shebang line in a login shell, as when you log in: the login
   files (`/etc/profile`, `/etc/profile.d/`, and `~/.bash_profile` or `~/.profile`) run first,
   so tools they put on your `PATH`, such as mise or Cargo, are found. On FreeBSD, whose `sh`
   has no login option, `/etc/profile` and `~/.profile` are read instead, so anything
   `~/.profile` prints at login, such as FreeBSD's `fortune` tip, shows in the output. It then gets the
   variables from the manifest's `environment_variables` and from `~/.env.d/`, which take
   priority over the login files. A script that exits with an error stops the node's remaining
   steps. A script has no time limit: one that never ends holds its node's place until you
   stop the command.

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

- Run the command from the lab's folder, where `sherpa up` wrote `.sherpa/ssh/config`.
- One of your [registered SSH keys](../ssh-keys.md), in your SSH agent or your default key
  files: provisioners log in to each node with it, as `sherpa ssh` does.
- Nothing extra on your machine: the `sherpa` CLI has its own SSH client. No `ssh` or `scp`
  program is used.
- A route from your machine to the lab's management network: run the command on the Sherpa
  server, or on a machine on the lab's [tailnet](../networking/tailscale.md) that accepts its
  routes. A node your machine cannot reach fails at once, saying so; it is not retried until the
  ready timeout. Otherwise add `--ssh-jump` to `sherpa up`, `sherpa provision` or
  `sherpa redeploy` to go through the Sherpa server, which needs a login to the server's host;
  see [SSH](../ssh.md#jump-through-the-sherpa-server).
- If your key has a passphrase, or the Sherpa server needs your password for the jump, you are
  asked once, even when nodes are provisioned at the same time, and the answer is used for the
  other nodes. A node is never asked for a password. A key loaded in your SSH agent needs no
  prompt.
- One of these virtual machine models: `alma_linux`, `alpine_linux`, `centos_linux`,
  `devbox_linux`, `fedora_linux`, `flatcar_linux`, `kali_linux`, `nixos_linux`,
  `omarchy_linux`, `opensuse_linux`, `redhat_linux`, `rocky_linux`, `suse_linux`,
  `ubuntu_linux`, `free_bsd` and `open_bsd`. `sherpa validate` and `sherpa up` refuse an `ssh`
  provisioner on any other model, `talos_linux`, `sonic_linux`, `generic` and the server
  appliances included, naming the node and the model.

## Limits

- **As the login user.** Files can only go where the login user can write. Use a script with
  `sudo`, or `doas` on Alpine and OpenBSD, for anything else.
- Removing a file from the manifest does not remove it from the node.
