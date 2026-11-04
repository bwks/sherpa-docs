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
  --model juniper_vsrxv3 \
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
| ZTP Method           | CDROM           |
| Management Interface | fxp0            |
| Data Interfaces      | ge-0/0/0-7      |
| Interface Driver     | virtio          |

!!! note

    vSRX reads its startup config from a CD-ROM. Its factory config runs no DHCP client, so the
    TFTP method that older Sherpa releases used left it without a config. Upgrading the server to
    Sherpa 0.5.8 moves existing vSRX images to the CD-ROM method.

## Example Manifest

```toml
name = "juniper-vsrxv3"

[[nodes]]
name = "dev01"
model = "juniper_vsrxv3"
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
