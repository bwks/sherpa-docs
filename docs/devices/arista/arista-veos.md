# Arista vEOS

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download). An account is required, which can be created without any support contract.
Download both a `VM image` and an `aboot` image.

### Notes

- vEOS requires an aboot ISO boot disk.
- vEOS is tested with `Aboot-veos-serial-8.0.2.iso`

## Import Node

```
sherpa image import TODO
```

## Node Parameters

| Property             | Value        |
| -------------------- | ------------ |
| Tested Version       | 4.32.2f      |
| CPU                  | 2            |
| RAM                  | 2GB          |
| CDROM                | aboot.iso    |
| CDROM Driver         | IDE          |
| DISK                 | virtio.qcow2 |
| DISK Driver          | SATA         |
| ZTP Method           | TFTP         |
| Management Interface | mgmt1        |
| Data Interfaces      | eth1-48      |
| Interface Driver     | virtio       |

## Example Manifest

```toml
name = "silly-sausage"

devices = [
  { name = "dev01", model = "arista_veos" },
]
```
