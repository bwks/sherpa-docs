# MySQL

MySQL is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/_/mysql).

### Import image

Pull the image through Sherpa, giving the full image reference:

```
sherpa server image pull --model mysql_db --repo mysql:8.0
```

Sherpa records the version (`8.0`) and the repo it was pulled from (`mysql`). A node with
that version runs that repo, unless it sets `image` in the manifest. An image pulled only with
the `docker` CLI is not known to Sherpa, so a lab cannot use it.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP Method           | Volume    |
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
