# Fedora Linux

## Base Image

Base images can be downloaded from [Fedora Cloud Images](https://fedoraproject.org/cloud/download).

Look for the Generic No Cloud image.

## Import Image

```
sherpa image import \
  --src Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2 \
  --model fedora_linux \
  --version 43-1.6 \
  --latest
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 43-1.6          |
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
name = "fedora-linux"

nodes = [
  { name = "dev01", model = "fedora_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
