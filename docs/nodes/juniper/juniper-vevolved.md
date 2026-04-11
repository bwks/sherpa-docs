# Juniper vEvolved

## Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vjunos-evolved) page.

## Import Image

```
sherpa server image import \
  --src vJunosEvolved-25.2R1.8-EVO.qcow2 \
  --version 25.2R1.8 \
  --model juniper_vevolved \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 25.2R1.8        |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | TFTP            |
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

### TFTP

The Juniper documentation states that a secondary attached disk is the method to provide an initial
config on first boot. However, I could not get this to work with the latest version: `25.2R1.8`.
Therefore, the TFTP method is selected for this device type as default.


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

- Approximate time for the system to be ready: `9 minutes`
