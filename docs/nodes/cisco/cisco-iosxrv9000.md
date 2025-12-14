# Cisco IOS-XRv 9000

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src /tmp/xrv9k-fullk9-7.11.1/virtioa.qcow2 \
  --version 7.11.1 \
  --model cisco_iosxrv9000 \
  --latest
```

## Node Parameters

| Property             | Value                |
| -------------------- | -------------------- |
| Kind                 | Virtual Machine      |
| Tested Version       | 7.11.1               |
| CPU                  | 4                    |
| RAM                  | 20GB                 |
| CDROM Driver         | SATA                 |
| DISK                 | virtioa.qcow2        |
| DISK Driver          | SATA                 |
| ZTP Method           | CDROM                |
| Management Interface | mgmt0eth0/rp0/cpu0/0 |
| Data Interfaces      | gig0/0/0-30          |
| Interface Driver     | virtio               |

## Example Manifest

```toml
name = "cisco-iosxrv9000"

nodes = [
  { name = "dev01", model = "cisco_iosxrv9000" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `10 minutes`
