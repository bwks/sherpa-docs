# SurrealDB

SurrealDB is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/r/surrealdb/surrealdb).

### Import image

Pull the image through Sherpa:

```
sherpa server image pull --model surreal_db --repo surrealdb/surrealdb:v2.2
```

Sherpa records the version, so a lab can use it. An image already pulled with the `docker` CLI
is not known to Sherpa until it is scanned. The scan records each local tag of `surrealdb/surrealdb` as a
version:

```
docker pull surrealdb/surrealdb:v2.2
sherpa server image scan --kind container
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
name = "surrealdb"

[[nodes]]
name = "db01"
model = "surreal_db"
version = "v2.2"
```


## Root User

SurrealDB serves its API on port `8000`, on the node's management address, in memory. It starts
with one root user, `root`, with a random password Sherpa generates for the node when it is
created, different for each node.

`sherpa up` and `sherpa download` write the address, user and password to
`.sherpa/surrealdb/surrealdb-<node>.toml` in the lab folder, readable only by you:

```toml
address = "http://172.31.1.24:8000"
username = "root"
password = "…"
```

Only you, the lab's owner, can download it; an admin of the Sherpa server cannot. If you are in
another folder, or lost the file, run `sherpa download` from the lab folder. Connect with the
SurrealDB CLI:

```
surreal sql --endpoint http://<surrealdb_mgmt_ip>:8000 --username root --password '<password>'
```

Sherpa passes the root user in the `SURREAL_USER` and `SURREAL_PASS` environment variables, not
on the command line. Values you set in the node's [`environment_variables`](../../manifest.md)
override them, and then the file holds Sherpa's, not yours. Anyone in the Sherpa host's `docker`
group can read the password with `docker inspect`; membership of `docker` is root on the host, so
that gives nothing away that root does not already have.

## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Docker"

    ```
    docker exec -it <node-name>-<lab-id> sh
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`
- The database is in memory. `sherpa redeploy` starts an empty SurrealDB with the same root user
  and password, so your `.sherpa/surrealdb/surrealdb-<node>.toml` stays right.
