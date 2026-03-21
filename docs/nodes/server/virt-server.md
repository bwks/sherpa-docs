# Virt Server

Virt Server is a virtual machine based image built on top of a Linux base with cloud-init support. It provides a nested virtualization capable VM for running hypervisor workloads inside a lab.

## Base Image

A cloud-init enabled Linux qcow2 image is required.
You can use [this](https://github.com/bwks/packer-virt) packer template to build the image.

## Import Image

```
sherpa server image import \
  --src virt-server.qcow2 \
  --version 0.1.0 \
  --model virt_server \
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
name = "virt-server"

nodes = [
  { name = "virt01", model = "virt_server" },
]
```

## Node Access

=== "SSH"

    ```
    sherpa ssh virt01
    ```

=== "Console"

    ```
    sherpa console virt01
    ```

## Notes

- Approximate time for the system to be ready: `3 minutes`
