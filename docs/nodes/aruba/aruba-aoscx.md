# Aruba AOS-CX

## Base Image

The base image can be downloaded from the [HPE Support Portal](https://networkingsupport.hpe.com/globalsearch#q=aos-cx%20switch%20simulator&tab=all) and search for `aos-cx switch simulator`.

!!! Note

    An account is required to download the image.f

## Import Image

### Extract

The image is compressed in a `.zip` file so extract it.

```
unzip AOS-CX_Switch_Simulator_10_16_1010_ova.zip
```

### Convert

The image is in `ova` format and needs to be converted.

```
mkdir aos-ova && \
  tar -xvf AOS-CX_10_16_1010.ova -C aos-ova && \
  cd aos-ova && \
  qemu-img convert -p -f vmdk -O qcow2 arubaoscx-disk-image-genericx86-p4-20251110170622.vmdk aos-cx.qcow2
```

### Import

```
sherpa image import \
  --src aos-cx.qcow2 \
  --version 10.16 \
  --model aruba_aoscx \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 10.16           |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtio.qcow2    |
| DISK Driver          | SATA            |
| ZTP Method           | TFTP            |
| Management Interface | mgmt            |
| Data Interfaces      | 1/1/1-52        |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

nodes = [
  { name = "dev01", model = "aruba_aoscx" },
]
```

## Notes

- Approximate boot time to interactive: `1 minute`
