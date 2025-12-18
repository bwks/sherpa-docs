# Cumulus Linux

## Base Image

!!! Note

    Nvidia discontinued Cumulus-VX since version `5.13`. There is no current official way to
    download Cumulus-VX images.

## Import Image

```
sherpa image import \
  --src cumulus-vx-5.9.1.qcow2 \
  --model cumulus_linux \
  --version 5.9.1 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 5.9.1           |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 2GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | USB             |
| Management Interface | eth0            |
| Data Interfaces      | swp1-52         |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "cumulus-linux"

nodes = [
  { name = "dev01", model = "cumulus_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `2 minutes`
