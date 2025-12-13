# Free BSD

!!! warning

    The image fails to enable SSH on boot. Port 22 is already in use and SSH cannot bind.

## Base Image

Base images can be downloaded from [BSD CLoud Images](https://bsd-cloud-image.org/).

## Import Image

```

sherpa image import \
 --src freebsd-14.2-zfs-2024-12-08.qcow2 \
 --model free_bsd \
 --version 14.2 \
 --latest

```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 14.2            |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "free-bsd"

nodes = [
  { name = "dev01", model = "free_bsd" },
]
```

## Notes

- Approximate boot time to interactive: `1 minute`
- Tested with the `UFS` image.
