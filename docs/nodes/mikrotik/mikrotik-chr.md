# Mikrotik CHR

## Base Image

A base image that is compatible with Sherpa can be built
using [this](https://github.com/bwks/packer-mikrotik) Packer template.

## Import Image

```
sherpa server image import \
  --src chr-7.20.8.img \
  --model mikrotik_chr \
  --version 7.20.8 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 7.20.8          |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | IDE             |
| ZTP Method           | Disk            |
| Management Interface | ether1          |
| Data Interfaces      | eth1-8          |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

nodes = [
  { name = "dev01", model = "mikrotik_chr" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
