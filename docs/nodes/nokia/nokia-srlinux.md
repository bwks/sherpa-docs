# Nokia SR Linux

Nokia SR Linux is a container based image.

## Base Image

Base images can be obtained from the [Nokia SR Linux](https://github.com/nokia/srlinux-container-image) github container registry.

### Import image

Pull the image through Sherpa:

```
sherpa server image pull --model nokia_srlinux --version 25.10.1
```

Sherpa records the version, so a lab can use it. An image pulled only with the `docker` CLI is
not known to Sherpa, so a lab cannot use it.

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

[[nodes]]
name = "dev01"
model = "nokia_srlinux"
version = "25.10.1"
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
