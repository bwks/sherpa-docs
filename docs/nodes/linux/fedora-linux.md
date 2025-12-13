## Base Image

Base images can be downloaded from [Fedora Cloud Images](https://fedoraproject.org/cloud/download).

## Import Image

```
sherpa image import \
  --src Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2 \
  --model fedora_linux \
  --version 43-1.6 \
  --latest
```

## Node Parameters

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
| Management Interface | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

nodes = [
  { name = "dev01", model = "fedora_linux" },
]
```

## Notes

- Approximate boot time to interactive: `1 minute`
