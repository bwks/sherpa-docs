# Open BSD

## Base Image

Base images can be downloaded from [BSD CLoud Images](https://bsd-cloud-image.org/).

## Import Image

```
sherpa image import \
  --src openbsd-min.qcow2 \
  --model open_bsd \
  --version 7.8 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 7.8             |
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
name = "open-bsd"

nodes = [
  { name = "dev01", model = "open_bsd" },
]
```

## Notes

- Approximate boot time and for ZTP to complete: `1 minute`
