# Unikernel

Unikernels from [NanoVMs](https://nanovms.com/) are single-purpose machine images that run directly on the [KVM](https://linux-kvm.org/page/Main_Page) hypervisor using the [QEMU](https://wiki.qemu.org/Main_Page) emulator and the [Libvirt](https://libvirt.org) API.

Unlike traditional VMs, unikernels package an application with only the OS primitives it needs, resulting in a minimal footprint. In Sherpa, unikernels run through the same libvirt/QEMU pathway as virtual machines.

## How it Works

When a lab is created, Sherpa performs the following for each unikernel node:

1. **Clone** the base disk image from the [storage pool](storage.md) into the lab directory
2. **Resize** the boot disk if `boot_disk_size` is specified in the manifest
3. **Generate** a libvirt domain XML definition from the node's parameters
4. **Apply** [zero-touch provisioning](zero-touch-provisioning.md) configuration
5. **Define and start** the domain via the Libvirt API

This is the same process used for virtual machines.

## Resource Allocation

Default parameters for unikernel nodes:

| Property | Default |
| -------- | ------- |
| CPU | 1 vCPU |
| RAM | 1024 MiB |
| Data Interfaces | 1 |
| Interface Driver | `virtio` |
| ZTP Method | CloudInit |

These defaults can be overridden in the manifest.

## Image Management

Unikernel binaries are stored as `qcow2` disk images in the `bins_dir` directory (default: `/opt/sherpa/bins/`). Images are imported via `sherpa server image import` the same way as VM images.

## Networking

Unikernels use the same networking as virtual machines — virtio interfaces attached to the [management network](networking/node/management.md) and data plane links as defined in the manifest. See [Virtual Machine — Networking](virtual-machine.md#networking) for details.

## Console Access

Each unikernel provides two console access methods:

- **Serial Console** — TCP-based telnet console bound to the node's loopback IP on port `2323`. Connect via `sherpa console <node>`.
- **VNC** — graphics adapter with an auto-assigned port. See [VNC](vnc.md) for connection details.

## Lifecycle

| Operation | Description |
| --------- | ----------- |
| Create | Domain XML is defined and the unikernel is started |
| Stop | Unikernel is shut down via Libvirt |
| Resume | Stopped unikernel is restarted |
| Destroy | Domain is undefined and all associated disks are removed |

!!! note

    Unikernel nodes do not support the redeploy operation.
