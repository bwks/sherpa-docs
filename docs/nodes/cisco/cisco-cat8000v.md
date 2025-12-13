# Cisco CAT8000v

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src c8000v-universalk9_8G_serial.17.16.01a.qcow2 \
  --version 17.16.01a \
  --model cisco_cat8000v \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 17.16.01a       |
| CPU                  | 1               |
| RAM                  | 4GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CDROM           |
| Management Interface | gig1            |
| Data Interfaces      | gig2-16         |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "cisco-cat8000v"

nodes = [
  { name = "dev01", model = "cisco_cat8000v" },
]
```

## Notes

- Approximate boot time to interactive: `4 minutes`
