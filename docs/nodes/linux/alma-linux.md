# Alma Linux

## Base Image

Base images can be downloaded from [Alma Cloud Images](https://wiki.almalinux.org/cloud/).

Look for the Generic No Cloud image.

## Import Image

```
sherpa image import \
  --src AlmaLinux-10-GenericCloud-latest.x86_64_v2.qcow2 \
  --model alma_linux \
  --version 10-20241125 \
  --latest
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 10-20241125     |
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
name = "alma-linux"

nodes = [
  { name = "dev01", model = "alma_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
