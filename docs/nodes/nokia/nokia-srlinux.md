# Nokia SR Linux

Nokia SR Linux is a container based image.

## Base Image

Base images can be obtained from the [Nokia SR Linux](https://github.com/nokia/srlinux-container-image) github container registry.

### Import image

Pull the image through Sherpa:

```
sherpa server image pull --model nokia_srlinux --version 26.7.2
```

Sherpa records the version, so a lab can use it. An image already pulled with the `docker` CLI
is not known to Sherpa until it is scanned. The scan records each local tag of `ghcr.io/nokia/srlinux` as a
version:

```
docker pull ghcr.io/nokia/srlinux:26.7.2
sherpa server image scan --container
```

The minimum supported release is 26.7.2. Sherpa 0.5.8 and later configure DNS as a
`dns-instance` named `mgmt`, which release 26 introduced in place of the `dns` client, so earlier
releases do not load the startup config.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `volume`  |
| Management Interface | mgmt0     |
| Data Interfaces      | eth-1/1-34         |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "nokia-srlinux"

[[nodes]]
name = "dev01"
model = "nokia_srlinux"
version = "26.7.2"
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
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node is the image as shipped: it starts with the image's own configuration, so once it has booted it has no management IP address, and it has no `sherpa` login. Nothing answers on the address the lab reserved for it, and `sherpa ssh` cannot reach it. Reach it with `docker exec -it <node-name>-<lab-id> sr_cli`. The node's `volumes` from the manifest are mounted, so you can supply a configuration of your own.
