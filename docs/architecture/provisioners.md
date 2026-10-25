# Provisioners

Provisioners get secrets onto lab nodes without the Sherpa server seeing them. Once a node is
ready, the `sherpa` CLI on your machine connects to it over SSH, through the Sherpa server as a
jump host, and copies your files and runs your scripts. The server only forwards the encrypted
SSH connection, so it never sees or stores the contents.

Use provisioners for passwords, API keys and tokens. The other manifest fields that put data on
a node (`environment_variables`, `text_files`, `startup_scripts` and `user_scripts`) are sent to
the server and stored there, so they are not for secrets.

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

See [`provisioners`](../manifest.md#provisioners-listobject) in the manifest reference for every
field.

## What the SSH Provisioner Does

Everything runs as the node's login user: your [personal account](personal-accounts.md) when
`provision_current_user` is enabled, otherwise the `sherpa` user. In order:

1. **Waits for the node.** It retries the login until the account exists, then waits for
   cloud-init to finish first-boot work, so your files are not overwritten by it.
2. **Copies `files`** with `scp`. Missing parent directories are created, private to the user.
   Each file is made private before its contents arrive, then given its `mode` (default `600`).
3. **Copies `env_files`** into `~/.env.d/`, mode `600`, and adds a line to `~/.bash_profile`, or
   to `~/.profile` when there is no `~/.bash_profile`, that loads every file in `~/.env.d/` in
   login shells, exporting its variables.
4. **Runs `scripts`.** The script is sent through the SSH session's input, never on a command
   line, and runs through its shebang line. It gets the variables from the manifest's
   `environment_variables` and from `~/.env.d/`. A script that exits with an error stops the
   node's remaining steps.

Provisioners on a node run in the order they are listed.

## When It Runs

- **`sherpa up`**: after the lab is created, on every node that came up with SSH. A node that
  was not ready is reported as skipped.
- **`sherpa redeploy`**: on the redeployed node, once it is back.
- **`sherpa provision`**: on demand, for all nodes or one with `--node`. Use it after a failure,
  or after changing a file. Running it again replaces the files and does not add the loader line
  twice.

The CLI prints a table with the result for each node, and exits with an error if any node was
not provisioned. The lab itself stays up.

## Requirements

- Run the command from the lab's folder, where `sherpa up` wrote `sherpa_ssh_config`.
- `ssh` and `scp` (OpenSSH) on your machine. Windows includes them.
- You can log in to the Sherpa server as the jump host without a prompt: your key in your SSH
  agent or `~/.ssh/config`, with no password or passphrase prompt. See [SSH](ssh.md#jumphost).
- Linux and BSD virtual machines only: the `cloud-init` Linux and BSD models, Alpine and
  Flatcar. Other nodes are rejected when the manifest is validated.

## Limits

- **CLI only.** Labs created from the web UI or the REST API cannot have provisioners, because
  only the CLI can run them. Such a manifest is refused with an error.
- **As the login user.** Files can only go where the login user can write. Use a script with
  `sudo` (or `doas` on Alpine) for anything else.
- **Root on the Sherpa server can still reach your nodes,** because it can read their memory and
  disks. Provisioners keep secrets away from everything the server stores and from other
  server users, not from the server's root user.
- Removing a file from the manifest does not remove it from the node.
