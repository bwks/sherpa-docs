# Arista vEOS

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download).

!!! note

    An account is required, which can be created without any support contract.

Both a Virtual Machine `QCOW2` image and a Boot Loader `ISO` are required.

### VM Image

The **64** bit image is recommended. Look for images named **vEOS64-lab-{version}.qcow2**

### Boot Loader

Download the `Aboot-veos-serial-8.0.2.iso` image which has the `serial` port drivers.

## Import Image

### Aboot ISO

The Aboot ISO image currently needs to be copied to each base image's version folder.
The most efficient method is to create a symlink to the source image to avoide duplicate files.

```
mkdir /opt/sherpa/images/arista_veos/aboot_iso/
cp /src/path/Aboot-veos-serial-8.0.2.iso /opt/sherpa/images/arista_veos/aboot_iso/aboot.iso
ln -s /opt/sherpa/images/arista_veos/aboot_iso/aboot.iso /opt/sherpa/images/arista_veos/4.34.4M/aboot.iso
ln -s /opt/sherpa/images/arista_veos/aboot_iso/aboot.iso /opt/sherpa/images/arista_veos/latest/aboot.iso
```

!!! warning

    The Aboot image must be named `aboot.iso`

### VM Image

```
sherpa image import \
  --src vEOS64-lab-4.34.4M.qcow2 \
  --version 4.34.4M \
  --model arista_veos \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 4.34.4M         |
| CPU                  | 2               |
| RAM                  | 2GB             |
| CDROM                | aboot.iso       |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | TFTP            |
| Management Interface | mgmt1           |
| Data Interfaces      | eth1-52         |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "arista-veos"

nodes = [
  { name = "dev01", model = "arista_veos" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `3 minutes`
- vEOS is tested with `Aboot-veos-serial-8.0.2.iso`
