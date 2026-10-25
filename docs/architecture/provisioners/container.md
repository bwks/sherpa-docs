# Container

The `container` provisioner gives a container secret files. The `sherpa` CLI sends them to the
Sherpa server, which keeps them in memory only and mounts them in the container, read-only, at
`/run/secrets/<name>` before it starts, so the container's entrypoint can read them.

## Example

```toml
[[nodes]]
name = "db01"
model = "mongo_db"
environment_variables = [
  "MONGO_INITDB_ROOT_USERNAME=admin",
  "MONGO_INITDB_ROOT_PASSWORD_FILE=/run/secrets/mongo_password",
]

[[nodes.provisioners]]
type = "container"

[[nodes.provisioners.files]]
src = "secrets/mongo-password"
name = "mongo_password"
```

Many images read secrets from a file named in a `*_FILE` environment variable, as
`MONGO_INITDB_ROOT_PASSWORD_FILE` does above. Each file has mode `444` unless you set `mode`, so
a container that does not run as root can read it.

See [`provisioners`](../../manifest.md#provisioners-listobject) in the manifest reference for
every field.

## Files Only

A value put in a container's environment is stored by Docker on the server's disk, so a secret
in `environment_variables` is not protected. Pass secrets as files, and point the image at them.

## How the Server Keeps Them

- They are sent with `sherpa up` and `sherpa redeploy`, outside the manifest, and never saved
  with the lab, written to the server's disk, or logged.
- They are kept in a RAM-backed folder that only the Sherpa service can read: not other server
  users, and not Sherpa administrators without root.
- They stay while the container exists, also when you stop and resume the lab or the Sherpa
  service restarts, and are removed when you destroy the lab.
- A server reboot clears them. The container then cannot start until you run
  `sherpa provision` from the lab's folder, which sends them again.

## When It Runs

- **`sherpa up`**: the files are sent with the lab and mounted before the containers start.
- **`sherpa redeploy`**: the container gets the files in the manifest now. Removing its
  provisioner removes them. A redeploy from the web UI keeps the files the container has.
- **`sherpa provision`**: sends the files again, to a running container. A container created
  without secret files must be redeployed to get them, as its mounts are fixed when it is
  created.

## Limits

- **The server holds them in memory.** Unlike the [`ssh`](ssh.md) provisioner, the server sees
  container secret files while it mounts them.
- Containers only.
