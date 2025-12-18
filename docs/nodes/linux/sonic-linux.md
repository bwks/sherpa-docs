# Sonic Linux

## Base Image

Base images can be downloaded from [TBC]().

!!! Warning

    Virtual Machine images from [sonic.software](https://sonic.software/) do not have ZTP enabled
    during compilation. If you obtain your image from there, ZTP will not work.

## Import Image

```
sherpa image import \
  --src sonic-vs.img \
  --model sonic_linux \
  --version 20251215 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 20251215        |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | HTTP            |
| Management Interface | eth0            |
| Data Interfaces      | eth1-52         |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "sonic-linux"

nodes = [
  { name = "dev01", model = "sonic_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `2 minutes`
