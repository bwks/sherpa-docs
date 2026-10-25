# Overview

Provisioners get secrets onto lab nodes without the Sherpa server storing them. Use them for
passwords, API keys and tokens. The other manifest fields that put data on a node
(`environment_variables`, `text_files`, `startup_scripts` and `user_scripts`) are sent to the
server and stored there, so they are not for secrets.

Each node lists its provisioners in the manifest, and each provisioner has a `type`:

| Type | Nodes | How secrets reach the node |
| ---- | ----- | -------------------------- |
| [`ssh`](ssh.md) | Linux and BSD virtual machines | The `sherpa` CLI connects to the node over SSH, through the Sherpa server as a jump host, and copies your files and runs your scripts. The server only forwards the encrypted connection, so it never sees the contents. |
| [`container`](container.md) | Containers | The CLI sends your secret files to the server, which keeps them in memory only and mounts them in the container at `/run/secrets` before it starts. |

A node's provisioners run in the order they are listed. See
[`provisioners`](../../manifest.md#provisioners-listobject) in the manifest reference for every
field.

## When They Run

- **`sherpa up`**: container secret files are sent with the lab and mounted before the
  containers start. `ssh` provisioners run once the lab is created.
- **`sherpa redeploy`**: on the redeployed node.
- **`sherpa provision`**: on demand, from the lab's folder, for all nodes or one with `--node`.
  Use it after a failure, after changing a file, or after a server reboot.

The CLI prints a table with the result for each node, and exits with an error if any node was
not provisioned. The lab itself stays up.

## Limits

- **CLI only.** Labs created from the web UI or the REST API cannot have provisioners, because
  only the CLI can run them. Such a manifest is refused with an error.
- **Root on the Sherpa server can still reach your nodes,** because it can read their memory,
  disks and container files. Provisioners keep secrets away from everything the server stores
  and from other server users, not from the server's root user.
- Nodes of other kinds, such as network devices and Windows, have no provisioner type. A
  provisioner on one is rejected when the manifest is validated.
