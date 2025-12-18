# Debian Linux

## Base Image

Base images can be downloaded from [Debian Cloud Images](https://cloud.debian.org/images/cloud/).

## Import Image

```
sherpa image import \
  --src debian-13-nocloud-amd64-20251117-2299.qcow2 \
  --model debian_linux \
  --version 13-20251117 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 13-20251117     |
| Kind                 | Virtual Machine |
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
name = "debian-linux"

nodes = [
  { name = "dev01", model = "debian_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
