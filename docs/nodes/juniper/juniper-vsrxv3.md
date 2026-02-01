# Juniper vSRX v3

## Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vsrxeval) page.

!!! Note

    An account is required to download the image.

## Import Image

```
sherpa image import \
  --src junos-vsrx3-x86-64-23.2R2.21.qcow2 \
  --version 23.2R2.21 \
  --model juniper_vsrxv3 \
  --latest
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
| Management Interface | fxp0/0          |
| Data Interfaces      | ge-0/0/0-7      |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "juniper-vsrxv3"

nodes = [
  { name = "dev01", model = "juniper_vsrxv3" },
]
```

## ZTP

ZTP config must be provided in a file named `juniper.conf` in the root directory of an `ISO` image.

## Notes

- Approximate time for the system to be ready: `4 minutes`
