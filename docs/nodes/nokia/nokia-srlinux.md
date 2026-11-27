# Nokia SR Linux

Nokia SR Linux is a container based image.

## Base Image

Base images can be obtained from the [Nokia SR Linux](https://github.com/nokia/srlinux-container-image) github container registry.

### Import image

Pull the image through Sherpa:

```
sherpa server image pull --model nokia_srlinux --version 26.3.1
```

Sherpa records the version, so a lab can use it. An image already pulled with the `docker` CLI
is not known to Sherpa until it is scanned. The scan records each local tag of `ghcr.io/nokia/srlinux` as a
version:

```
docker pull ghcr.io/nokia/srlinux:26.3.1
sherpa server image scan --kind container
```

Sherpa's startup config is tested on release 26.3.1. It configures DNS as a
`dns-instance` named `mgmt`, which SR Linux takes from release 26, so earlier releases reject it.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | Not limited in the sandbox |
| RAM                  | Not limited in the sandbox |
| ZTP                  | `volume`  |
| Management Interface | mgmt0     |
| Data Interfaces      | eth-1/1-34         |
| Interface Driver     | virtio     |

## Example Manifest

```toml
name = "nokia-srlinux"

[[nodes]]
name = "dev01"
model = "nokia_srlinux"
version = "26.3.1"
```


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node is the image as shipped: it starts with the image's own configuration, whose DHCP client on `mgmt0.0` takes the management address the lab reserved for it, and it has no `sherpa` login, so `sherpa ssh` cannot log in. Reach it with `sherpa console <node-name>`. The node's `volumes` from the manifest are copied into the node when it is created, so you can supply a configuration of your own.

## Sandbox

SR Linux runs in a [sandbox](../../architecture/sandboxes.md): a Flatcar VM of its own, which
Sherpa handles as a virtual machine for `down`, `resume` and `status`.

- The container is privileged in that VM, so its privileges reach the VM's kernel, not the
  server's.
- `sherpa console <node>` opens `sr_cli` on the VM's serial console: press Enter. `sherpa vnc`
  is refused.
- The VM gets the node's `memory` plus 1024 MiB and its `cpu.count` vCPUs.
- Volumes are copied when the node is created, so a change on the server needs a `sherpa redeploy`.
  What SR Linux saves stays in the VM across `sherpa down` and `sherpa resume`.
- The server needs the [`flatcar_sandbox`](../linux/flatcar-sandbox.md) image, which you import
  once. The sandbox has a management address of its own, named `<node>-sbx`.
- A node is ready once SSH answers. With a config of your own it is ready once the container
  started, unless `ready_check.port` says otherwise.
