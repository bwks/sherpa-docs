# Arista vEOS

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download).
An account is required, which can be created without any support contract.

Both a Virtual Machine `QCOW2` image and a Boot Loader `ISO` are required.

### VM Image

The **64** bit image is recommended. Look for images named **vEOS64-lab-{version}.qcow2**

### Boot Loader

Download the `Aboot-veos-serial-8.0.2.iso` image which has the `serial` port drivers.

## Import Image

### Aboot ISO

TODO: Update this

### VM Image

```
sherpa image import \
  --src vEOS64-lab-4.35.0F.qcow2 \
  --version 4.35.0F \
  --model arista_veos \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 4.32.2f         |
| CPU                  | 2               |
| RAM                  | 2GB             |
| CDROM                | aboot.iso       |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | TFTP            |
| Management Interface | mgmt1           |
| Data Interfaces      | eth1-48         |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "arista-veos"

nodes = [
  { name = "dev01", model = "arista_veos" },
]
```

## Notes

- Approximate boot time to interactive: `3 minutes`
- vEOS is tested with `Aboot-veos-serial-8.0.2.iso`
