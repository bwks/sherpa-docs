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

Sherpa records the version, so a lab can use it. An image already pulled with the `docker` CLI
is not known to Sherpa until it is scanned. The scan records each local tag of `quay.io/frrouting/frr` as a
version:

```
docker pull quay.io/frrouting/frr:10.5.2
sherpa server image scan --container
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `volume`  |
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
- The node installs OpenSSH, sudo and lldpd from the Alpine package repositories when it boots,
  so the Sherpa server needs internet access. It tries 10 times, 3 seconds apart. If every try
  fails, the node has no SSH: use `docker exec` instead, and check the node's log with
  `docker logs <node-name>-<lab-id>`.
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node is the image as shipped: it runs the image's own entrypoint and `daemons` file. Sherpa mounts no configuration, installs no SSH server and adds no logins. The node still answers on its management address, but `sherpa ssh` cannot connect: reach it with `docker exec -it <node-name>-<lab-id> sh`. The node's `volumes` from the manifest are mounted, so you can supply a configuration of your own.
