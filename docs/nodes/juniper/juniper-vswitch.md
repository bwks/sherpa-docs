# Juniper vSwitch

## Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vjunos) page.

## Import Image

```
sherpa image import \
  --src vJunos-switch-25.2R1.9.qcow2 \
  --version 25.2R1.9 \
  --model juniper_vswitch \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 25.2R1.9        |
| CPU                  | 4               |
| RAM                  | 5GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CDROM           |
| Management Interface | fxp0/0          |
| Data Interfaces      | ge-0/0/0-9      |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "juniper-vswitch"

nodes = [
  { name = "dev01", model = "juniper_vswitch" },
]
```

## ZTP

ZTP config must be provided in a file named `juniper.conf` in the root directory of an `ISO` image.

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `4 minutes`
