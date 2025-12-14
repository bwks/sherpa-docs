# Cisco IOSvL2

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src /tmp/vios_l2-adventerprisek9-m.ssa.high_iron_20200929.qcow2 \
  --version 20200929 \
  --model cisco_iosvl2 \
  --latest
```

## ZTP Disk

IOSvl2 requires a disk formatted in a particular way. If not completed during the system install,
run the `scripts/create_iosv_disk.sh` script to create the base disk. This base disk will be created
in the `/opt/sherpa/images/blank_disk` directory. This only needs to occur once as the base disk
is cloned during instance creation.

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 20200929        |
| CPU                  | 1               |
| RAM                  | 768MB           |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | Disk            |
| Management Interface | gig0/0          |
| Data Interfaces      | gig[0-3]/0-3    |
| Interface Driver     | e1000           |

## Example Manifest

```toml
name = "cisco-iosvl2"

nodes = [
  { name = "dev01", model = "cisco_iosvl2" },
]
```

## Notes

- Approximate boot time and for ZTP to complete: `2 minutes`
