# MySQL

MySQL is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/_/mysql).

### Import image

Pull the image through Sherpa, giving the image reference with its tag:

```
sherpa server image pull --model mysql_db --repo mysql:8.0
```

Sherpa records the version (`8.0`) and the repo it was pulled from (`mysql`). A node with
that version runs that repo, unless it sets `image` in the manifest. An image already pulled
with the `docker` CLI is not known to Sherpa until it is scanned. `mysql_db` has no built-in repo,
so give the scan the model and the repo, without a tag; it records each local tag of the repo as
a version, with that repo:

```
docker pull mysql:8.0
sherpa server image scan --container --model mysql_db --repo mysql
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `disabled`|
| Management Interface | eth0      |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "mysql"

[[nodes]]
name = "db01"
model = "mysql_db"
version = "8.0"
environment_variables = [
  "MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password",
]

[[nodes.provisioners]]
type = "container"

[[nodes.provisioners.files]]
src = "secrets/mysql-root-password"
name = "mysql_root_password"
```

Put the root password in `secrets/mysql-root-password`, next to the manifest, before
`sherpa up`.

## Root Password

The `mysql` image refuses to start until it is told how to set the root password, and the
container exits at once. Sherpa sets none for `mysql_db`, so the node needs one of these in
`environment_variables`:

| Variable                          | Effect                                                    |
| --------------------------------- | --------------------------------------------------------- |
| `MYSQL_ROOT_PASSWORD_FILE`        | Root password read from a file, as in the example.        |
| `MYSQL_ROOT_PASSWORD`             | Root password given as the value.                         |
| `MYSQL_RANDOM_ROOT_PASSWORD=yes`  | A random root password, printed once in the container log as `GENERATED ROOT PASSWORD`. |
| `MYSQL_ALLOW_EMPTY_PASSWORD=yes`  | Root has no password. Anyone who reaches the node is root. |

The example passes the password as a file with the
[`container` provisioner](../../architecture/provisioners/container.md), so it is not stored
with the lab. `MYSQL_ROOT_PASSWORD` is simpler, but the password is then saved on the Sherpa
server and shown by `docker inspect`; see
[`environment_variables`](../../manifest.md#environment_variables-liststring).

The variables only take effect the first time the container starts, when MySQL creates its data
directory. The image also accepts `MYSQL_DATABASE`, `MYSQL_USER` and `MYSQL_PASSWORD` (or
`MYSQL_PASSWORD_FILE`) to create a database and a user. See the image's
[documentation](https://hub.docker.com/_/mysql) for the full list.


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Docker"

    ```
    docker exec -it <node-name>-<lab-id> sh
    ```

=== "MySQL client"

    ```
    docker exec -it <node-name>-<lab-id> mysql -u root -p
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`
