# Cisco IOSvL2

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 20200929 \
  --model cisco_iosl2 \
  --default
```

## ZTP Disk

IOSvL2 reads its config from a disk formatted in a particular way. Each node gets a copy of
`/opt/sherpa/images/blank_disk/iosv.img`, which the install and update scripts create (see
[Blank Disks](../../install-update/install/automated.md#blank-disks)). If it is missing, run the
[update script](../../install-update/update/sherpa.md) again: it creates the missing blank disks
and changes none that are there.

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 20200929        |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `disk`          |
| Management Interface | GigabitEthernet0/0 |
| Data Interfaces      | gig0/1-3, gig1/0-3, gig2/0-3, gig3/0-3 |
| Interface Driver     | e1000           |

## Example Manifest

```toml
name = "cisco-iosvl2"

[[nodes]]
name = "dev01"
model = "cisco_iosl2"
```


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Approximate time for the system to be ready: `2 minutes`
