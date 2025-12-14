# Net BSD

## Base Image

Base images can be downloaded from [BSD CLoud Images](https://bsd-cloud-image.org/).

## Import Image

```

sherpa image import \
 --src netbsd-10.1-2025-02-15.qcow2 \
 --model net_bsd \
 --version 10.1 \
 --latest

```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 10.1            |
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
name = "net-bsd"

nodes = [
  { name = "dev01", model = "net_bsd" },
]
```

## Notes

- Approximate boot time and for ZTP to complete: `1 minute`
- Tested with the `UFS` image.
