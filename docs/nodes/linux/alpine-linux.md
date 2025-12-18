# Alpine Linux

## Base Image

Base images can be downloaded from [Alpine Cloud Images](https://alpinelinux.org/cloud/).

Look for the `No Cloud` image with `cloud-init` enabled.

## Import Image

```
sherpa image import \
  --src nocloud_alpine-3.23.0-x86_64-bios-cloudinit-r0.qcow2 \
  --model alpine_linux \
  --version 3.23.0 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 3.23.0          |
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
name = "alpine-linux"

nodes = [
  { name = "dev01", model = "alpine_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
