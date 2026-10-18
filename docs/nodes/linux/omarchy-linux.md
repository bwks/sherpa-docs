# Omarchy Linux

## Base Image

Omarchy does not publish a cloud-ready disk image. Install Omarchy, then prepare the installed
disk with `cloud-init` installed and enabled and a clean instance state. Save it as a `qcow2` file.

!!! Warning
    The Omarchy installer ISO cannot be used as an image. Sherpa does not run the installer.

## Import Image

```
sherpa server image import \
  --src /absolute/path/omarchy.qcow2 \
  --version <version> \
  --model omarchy_linux \
  --default
```

!!! Note
    The `--src` path is on the server.

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
