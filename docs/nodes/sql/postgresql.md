# PostgreSQL

PostgreSQL is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/_/postgres).

### Import image

Pull the image through Sherpa, giving the image reference with its tag:

```
sherpa server image pull --model postgresql_db --repo postgres:17
```

Sherpa records the version (`17`) and the repo it was pulled from (`postgres`). A node with
that version runs that repo, unless it sets `image` in the manifest. An image already pulled
with the `docker` CLI is not known to Sherpa until it is scanned. `postgresql_db` has no built-in repo,
so give the scan the model and the repo, without a tag; it records each local tag of the repo as
a version, with that repo:

```
docker pull postgres:17
sherpa server image scan --container --model postgresql_db --repo postgres
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP                  | `disabled`|
| Management Interface | eth0      |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "postgresql"

[[nodes]]
name = "db01"
model = "postgresql_db"
version = "17"
```


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
