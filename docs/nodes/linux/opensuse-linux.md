# OpenSUSE Linux

## Base Image

Base images can be downloaded from [OpenSUSE Cloud Images](https://download.opensuse.org/repositories/Cloud:/Images:/).

## Import Image

```
sherpa image import \
  --src openSUSE-Leap-15.6.x86_64-NoCloud.qcow2 \
  --model opensuse_linux \
  --version 15.6 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 15.6            |
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
name = "opensuse-linux"

nodes = [
  { name = "dev01", model = "opensuse_linux" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `1 minute`
