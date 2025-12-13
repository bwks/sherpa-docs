# Cisco ASAv

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src asav9-23-1.qcow2 \
  --version 9-23-1 \
  --model cisco_asav \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 9-23-1          |
| CPU                  | 1               |
| RAM                  | 2GB             |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | CDROM           |
| Management Interface | mgmt0/0         |
| Data Interfaces      | gig0-8          |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "cisco-asav"

nodes = [
  { name = "dev01", model = "cisco_asav" },
]
```

## Notes

- Approximate boot time to interactive: `3 minutes`
- ASAv forces a password reset on first login.
