# Nokia SR Linux

Nokia SR Linux is a container based image.

## Base Image

Base images can be obtained from the [Nokia SR Linux](https://github.com/nokia/srlinux-container-image) github container registry.

### Import image

#### Sherpa

```
sherpa server image pull ghcr.io/nokia/srlinux:25.10.1
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull ghcr.io/nokia/srlinux:25.10.1
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 2         |
| RAM                  | 4GB       |
| ZTP Method           | Volume    |
| Management Interface | mgmt0     |
| Data Interfaces      | eth-1/1-34         |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "nokia-srlinux"

nodes = [
  { name = "dev01", model = "nokia_srlinux", version = "25.10.1" },
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
