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
GH_TOKEN=ghp_example
ANTHROPIC_API_KEY='sk-example'
```

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
3. **Copies `env_files`** into `~/.env.d/`, mode `600`, and adds a line to `~/.bash_profile`, or
   to `~/.profile` when there is no `~/.bash_profile`, that loads every file in `~/.env.d/` in
   login shells, exporting its variables.
4. **Runs `scripts`.** The script is sent through the SSH session's input, never on a command
   line, and runs through its shebang line. It gets the variables from the manifest's
   `environment_variables` and from `~/.env.d/`. A script that exits with an error stops the
   node's remaining steps.

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
  needs your password, you are asked once, when the first node is provisioned, and the
  answer is used for the other nodes. A key loaded in your SSH agent needs no prompt. See
  [SSH](../ssh.md#jumphost).
- Linux and BSD virtual machines only: the `cloud-init` Linux and BSD models, Alpine and
  Flatcar.

## Limits

- **As the login user.** Files can only go where the login user can write. Use a script with
  `sudo`, or `doas` on Alpine and OpenBSD, for anything else.
- Removing a file from the manifest does not remove it from the node.
