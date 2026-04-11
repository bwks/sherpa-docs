# MySQL

MySQL is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/_/mysql).

### Import image

#### Sherpa

```
sherpa server image pull mysql:8.0
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull mysql:8.0
```

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

nodes = [
  { name = "db01", model = "mysql", version = "8.0" },
]
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
