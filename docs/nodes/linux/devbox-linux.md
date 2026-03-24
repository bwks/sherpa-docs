# Devbox Linux

Devbox Linux is a developer workstation virtual machine based on Ubuntu with cloud-init support.

## Base Image

A cloud-init enabled Ubuntu based qcow2 image is required.
You can use [this](https://github.com/bwks/packer-devbox) packer template to build the image.

## Import Image

```
sherpa server image import \
  --src devbox-linux-ubuntu-24.04.01.qcow2 \
  --version ubuntu-24.04.01 \
  --model devbox_linux \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Data Interfaces      | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "devbox-linux"

nodes = [
  { name = "dev01", model = "devbox_linux" },
]
```

## Node Access

=== "SSH"

    ```
    sherpa ssh dev01
    ```

=== "Console"

    ```
    sherpa console dev01
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`
