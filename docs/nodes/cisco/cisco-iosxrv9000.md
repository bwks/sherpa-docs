# Cisco IOS-XRv 9000

!!! Warning

    Not working. ZTP config is applied, but cannot ssh to node.
    Outbound connectivity is ok.

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src xrv9k-fullk9-x-25.1.1.qcow2 \
  --version 25.1.1 \
  --model cisco_iosxrv9000 \
  --latest
```

## Node Parameters

| Property             | Value                |
| -------------------- | -------------------- |
| Kind                 | Virtual Machine      |
| Tested Version       | 25.1.1               |
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

- Approximate time for the system to be ready: `20 minutes`
- Version `25.1.1` changed the bios to `uefi`. Previous versions used `sea_bios`
