# FRR Linux

FRRouting Linux is a container based image.

## Base Image

Base images can be obtained from the [FRRouting](https://quay.io/repository/frrouting/frr)
container registry.

### Import image

Pull the image through Sherpa:

```
sherpa server image pull --model frr_linux --version 10.5.2
```

Sherpa records the version, so a lab can use it. An image pulled only with the `docker` CLI is
not known to Sherpa, so a lab cannot use it.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 512MB       |
| ZTP Method           | Volume    |
| Management Interface | eth0      |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "frr-linux"

[[nodes]]
name = "dev01"
model = "frr_linux"
version = "10.5.2"
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
