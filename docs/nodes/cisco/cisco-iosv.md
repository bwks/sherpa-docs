# Cisco IOSv

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src vios-adventerprisek9-m.spa.159-3.m10.qcow2 \
  --version 159-3.m10 \
  --model cisco_iosv \
  --latest
```

## ZTP Disk

IOSv requires a disk formatted in a particular way. If not completed during the system install,
run the `scripts/create_iosv_disk.sh` script to create the base disk. This base disk will be created
in the `/opt/sherpa/images/blank_disk` directory. This only needs to occur once as the base disk
is cloned during instance creation.

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 159-3.m10       |
| CPU                  | 1               |
| RAM                  | 512MB           |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | Disk            |
| Management Interface | gig0/0          |
| Data Interfaces      | gig0/0-15       |
| Interface Driver     | e1000           |

## Example Manifest

```toml
name = "cisco-iosv"

nodes = [
  { name = "dev01", model = "cisco_iosv" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `2 minutes`
