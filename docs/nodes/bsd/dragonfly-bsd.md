# DragonFly BSD

## Base Image

Base images can be downloaded from [BSD CLoud Images](https://bsd-cloud-image.org/).

## Import Image

```

sherpa image import \
 --src dragonflybsd-6.4.0-ufs-2023-04-23.qcow2 \
 --model dragonfly_bsd \
 --version 6.4.0 \
 --latest

```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 6.4.0           |
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
name = "dragonfly-bsd"

nodes = [
  { name = "dev01", model = "dragonfly_bsd" },
]
```

## Notes

- Approximate boot time to interactive: `1 minute`
- Tested with the `UFS` image.
