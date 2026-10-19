# Omarchy Linux

## Base Image

Omarchy does not publish a cloud-ready disk image. A cloud-init enabled Omarchy qcow2 image is
required. You can use [this](https://github.com/bwks/packer-omarchy-linux) packer template to
build the image. It runs the official Omarchy installer unattended, adds `cloud-init`, and writes
the image to `output/omarchy.qcow2`.

!!! Warning
    The Omarchy installer ISO cannot be used as an image. Sherpa does not run the installer.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 4.0.4 \
  --model omarchy_linux \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 4               |
| RAM                  | 8GB             |
| BIOS                 | UEFI            |
| Machine Type         | Q35             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Data Interfaces      | 1               |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "omarchy-lab"

[[nodes]]
name = "desktop"
model = "omarchy_linux"
version = "<version>"
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

- The administrator group is `wheel`, as on Arch Linux.
- Management networking, the Sherpa user, file injection and startup scripts work the same way as other cloud-init Linux nodes.
