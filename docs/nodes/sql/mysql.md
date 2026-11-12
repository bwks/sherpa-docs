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
| CPU                  | 1         |
| RAM                  | 1GB       |
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
