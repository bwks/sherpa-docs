# Virtual Machine

Virtual machines are supported via the [KVM](https://linux-kvm.org/page/Main_Page) hypervisor using the [QEMU](https://wiki.qemu.org/Main_Page) emulator and the [Libvirt](https://libvirt.org) virtualisation API.

## How it Works

When a lab is created, Sherpa performs the following for each VM node:

1. **Clone** the base disk image from the [storage pool](storage.md) into the lab directory
2. **Resize** the boot disk if `boot_disk_size` is specified in the manifest
3. **Generate** a libvirt domain XML definition from the node's parameters
4. **Apply** [zero-touch provisioning](zero-touch-provisioning.md) configuration (cloud-init ISO, ZTP scripts, etc.)
5. **Define and start** the domain via the Libvirt API

Each VM runs as a persistent libvirt domain under KVM/QEMU.

## Resource Allocation

Every node model has default resource parameters that can be overridden in the manifest. Typical defaults:

| Resource | Range | Examples |
| -------- | ----- | -------- |
| CPU | 1–4 vCPUs | Cisco ASAv: 1, Arista vEOS: 2, Cisco Cat9000v: 4 |
| RAM | 2048–20480 MiB | Cisco ASAv: 2048, Cisco CSR1000v: 3072, Cisco XRv9000: 20480 |
| Machine Type | `pc`, `q35` variants | Most use `pc`, some require specific `q35` versions |
| BIOS | SeaBIOS or UEFI | Most use SeaBIOS; XRv9000, Nexus 9300v use UEFI |

CPU mode defaults to `host-model`, which auto-detects the host CPU capabilities. Nested virtualisation is supported via the VMX CPU flag when required.

## Disk Management

Base images are stored in the Sherpa [storage pool](storage.md) (`sherpa-pool`). When a lab starts, each VM's base image is cloned into the lab directory at `/opt/sherpa/labs/<lab-id>/`. The original base image is never modified.

Supported disk formats: `qcow2`, `raw`, `iso`, `img`.

Disk drivers vary by model:

| Driver | Usage |
| ------ | ----- |
| `virtio` | Default for most models |
| `sata` | Used by some models that lack virtio support |
| `ide` | Legacy models |

Boot disk resizing increases the volume capacity via the Libvirt storage API. The new size must be larger than the current allocation.

## Networking

VM network interfaces are attached as libvirt network devices. The interface driver is configurable per model:

| Driver | Usage |
| ------ | ----- |
| `virtio` | Default for most models |
| `e1000` | Models that require Intel NIC emulation |
| `vmxnet3` | VMware-compatible models |

Each VM is connected to the [management network](networking/node/management.md) on its first interface. Additional interfaces are attached for data plane links as defined in the manifest. Point-to-point links between VMs use UDP tunnels over the loopback address.

## Console Access

Each VM provides two console access methods:

### Serial Console

A TCP-based telnet serial console is configured on each VM, bound to the loopback address with an auto-assigned port. Connect via `sherpa console <node>` or directly with:

```bash
telnet 127.0.0.1 <console-port>
```

### VNC

A VNC graphics adapter is configured on each VM with an auto-assigned port. See [VNC](vnc.md) for connection details.

## Lifecycle

| Operation | Description |
| --------- | ----------- |
| Create | Domain XML is defined and the VM is started |
| Stop | VM is shut down via Libvirt |
| Resume | Stopped VM is restarted |
| Redeploy | VM is destroyed, disks are deleted, and the node is recreated with fresh configuration |
| Destroy | Domain is undefined and all associated disks are removed |

Power behaviour:

- **On poweroff** — VM is destroyed
- **On reboot** — VM is restarted
- **On crash** — VM is destroyed

## Additional Features

- **Watchdog** — i6300esb hardware watchdog with reset action for crash recovery
- **QEMU Guest Agent** — virtio channel for host-guest communication
- **NVRAM** — UEFI VMs store NVRAM at `/var/lib/libvirt/qemu/nvram/`
- **Windows support** — Hyper-V enlightenments (relaxed, vapic, spinlocks) are enabled for Windows VMs
