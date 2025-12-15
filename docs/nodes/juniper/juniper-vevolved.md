# Juniper vEvolved

!!! Warning

    Not working

## Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vjunos-evolved) page.

## Import Image

```
sherpa image import \
  --src vJunosEvolved-25.2R1.8-EVO.qcow2 \
  --version 25.2R1.8 \
  --model juniper_vevolved \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 25.2R1.8        |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | USB             |
| Management Interface | re0:mgmt-0      |
| Data Interfaces      | et-0/0/0-11     |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "juniper-vevolved"

nodes = [
  { name = "dev01", model = "juniper_vevolved" },
]
```

## ZTP

Juniper vEvolved requires a disk formatted in a particular way. If not completed during the system install,
run the `scripts/create_blank_disks.sh` script to create the base disk. This base disk will be created
in the `/opt/sherpa/images/blank_disk` directory. This only needs to occur once as the base disk
is cloned during instance creation.

ZTP config must be provided in a file named `juniper.conf` in the root directory of a disk attached
as a `USB` removable disk. The disk must be formatted as vFAT and have the label `vmm-data`.

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `4 minutes`
