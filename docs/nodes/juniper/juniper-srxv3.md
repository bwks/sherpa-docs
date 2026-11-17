# Juniper vSRX v3

## Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vsrxeval) page.

!!! Note

    An account is required to download the image.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 23.2R2.21 \
  --model juniper_srxv3 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 23.2R2.21       |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `cdrom`         |
| Management Interface | fxp0            |
| Data Interfaces      | ge-0/0/0-7      |
| Interface Driver     | virtio          |

!!! note

    vSRX reads its startup config from a CD-ROM, the only ZTP method it takes: a node or image set
    to `tftp` is refused. Up to 0.6.5 vSRX also took `tftp`, which stalled the node without a
    config. Updating the server to 0.7.0 moves vSRX images set to `tftp` to `cdrom`; see
    [Updating to 0.7.0](../../install-update/update/sherpa.md#vsrx-takes-its-config-from-cd-rom-only).

## Example Manifest

```toml
name = "juniper-srx"

[[nodes]]
name = "dev01"
model = "juniper_srxv3"
```

## ZTP

ZTP config must be provided in a file named `juniper.conf` in the root directory of an `ISO` image.


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

- Approximate time for the system to be ready: `4 minutes`
