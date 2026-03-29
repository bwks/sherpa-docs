# Devbox Windows

Devboxes are nodes with a common set of tooling pre-installed.

## Base Image

A cloud-init enabled Windows qcow2 image is required.
You can use [this](https://github.com/bwks/packer-devbox-windows) packer template to build the image.

## Import Image

```
sherpa server image import \
  --src devbox.qcow2 \
  --version windows11-20260320 \
  --model devbox_windows \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 4GB             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Data Interfaces      | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "devbox-windows"

nodes = [
  { name = "dev01", model = "devbox_windows" },
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
