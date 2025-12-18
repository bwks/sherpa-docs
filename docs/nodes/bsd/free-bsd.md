# Free BSD

## Base Image

Base images can be downloaded from [BSD Cloud Images](https://bsd-cloud-image.org/).

## Import Image

```

sherpa image import \
 --src freebsd-14.2-ufs-2024-12-08.qcow2 \
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
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "free-bsd"

nodes = [
  { name = "dev01", model = "free_bsd" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
- Tested with the `UFS` image.
