# Rocky Linux

## Base Image

Base images can be downloaded from the [Rocky Downloads](https://rockylinux.org/download) page.

Look for the Generic No Cloud image.

## Import Image

```
sherpa image import \
  --src Rocky-10-GenericCloud-Base.latest.x86_64.qcow2 \
  --model rocky_linux \
  --version 10-20251215 \
  --latest
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 10-20251215     |
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
name = "rocky-linux"

nodes = [
  { name = "dev01", model = "rocky_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
