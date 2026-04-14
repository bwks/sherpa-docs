# Unikernel

Unikernels are single-purpose machine images that package an application with only the OS primitives it needs, resulting in a minimal footprint. In Sherpa, unikernels run on the [KVM](https://linux-kvm.org/page/Main_Page) hypervisor using the [QEMU](https://wiki.qemu.org/Main_Page) emulator and the [Libvirt](https://libvirt.org) API — the same pathway used for virtual machines.

Sherpa supports three unikernel models:

| Model | Boot Mode | Description |
| ----- | --------- | ----------- |
| `generic_unikernel` | DirectKernel | Generic type for custom unikernels |
| `unikraft_unikernel` | DirectKernel | [Unikraft](https://unikraft.org/)-based unikernels |
| `nanos_unikernel` | DiskBoot | [NanoVMs](https://nanovms.com/)-based unikernels |

## Boot Modes

Unikernels support two boot modes that determine how the hypervisor loads the application:

- **DirectKernel** — The kernel ELF binary is loaded directly by QEMU via the `<kernel>` libvirt XML element. An optional kernel command line can be passed via `<cmdline>` using the `kernel_cmdline` manifest parameter. No disk cloning is required.
- **DiskBoot** — The unikernel boots from a cloned disk image, the same way as a traditional VM (`<boot dev='hd'/>`).

## How it Works

When a lab is created, Sherpa performs the following for each unikernel node:

=== "DirectKernel"

    1. **Resolve** the kernel ELF path from the image store
    2. **Generate** a libvirt domain XML definition with the kernel path and optional `kernel_cmdline`
    3. **Define and start** the domain via the Libvirt API

=== "DiskBoot"

    1. **Clone** the base disk image from the [storage pool](storage.md) into the lab directory
    2. **Resize** the boot disk if `boot_disk_size` is specified in the manifest
    3. **Generate** a libvirt domain XML definition from the node's parameters
    4. **Define and start** the domain via the Libvirt API

All unikernel nodes are created in parallel after VM nodes have been provisioned.

## Resource Allocation

Default parameters for unikernel nodes:

| Property | Default |
| -------- | ------- |
| CPU | 1 vCPU |
| RAM | 512 MiB |
| Data Interfaces | 0 |
| Interface Driver | `virtio` |
| ZTP Method | None |

These defaults can be overridden in the manifest.

## Image Management

Unikernel images are stored in the `bins_dir` directory (default: `/opt/sherpa/bins/`), organised by model and version. The storage format depends on the boot mode:

| Boot Mode | Filename | Format |
| --------- | -------- | ------ |
| DirectKernel | `kernel.elf` | ELF binary |
| DiskBoot | `disk.qcow2` | QCOW2 disk image |

Images are imported via `sherpa server image import`:

```bash
sherpa server image import \
  --src <path-to-image> \
  --version <version> \
  --model <model_name>
```

Use the `--unikernel` flag with `sherpa server image list` or `sherpa server image scan` to filter for unikernel images.

## Networking

Unikernels use the same networking as virtual machines — virtio interfaces attached to the [management network](networking/node/management.md) and data plane links as defined in the manifest. See [Virtual Machine — Networking](virtual-machine.md#networking) for details.

## Console Access

Each unikernel provides a serial console for access:

- **Serial Console** — TCP-based telnet console bound to the node's unique loopback IP on port `2323`. Connect via `sherpa console <node>` or directly with `telnet <node-loopback-ip> 2323`.

!!! info

    Unikernels do not include a VNC graphics adapter. Serial console is the only access method.

## Manifest Configuration

Unikernel nodes support the following unikernel-specific manifest parameters:

- **`kernel_cmdline`** — Kernel command line arguments passed to QEMU for DirectKernel unikernels. This overrides any auto-injected command line. Use this to specify the application entry point or pass runtime configuration to the unikernel.
- **`ready_port`** — TCP port to probe on the node's management IP to verify readiness. By default, a unikernel is considered ready when its libvirt domain reaches the running state. When `ready_port` is set, Sherpa additionally waits for a successful TCP connection to the specified port.

```toml
nodes = [
  { name = "web01", model = "unikraft_unikernel", version = "v1.0.0", kernel_cmdline = "/usr/bin/nginx", ready_port = 80 },
]
```

See the [manifest](../manifest.md#optional-node-parameters) documentation for all available node parameters.

## Lifecycle

| Operation | Description |
| --------- | ----------- |
| Create | Domain XML is defined and the unikernel is started |
| Stop | Unikernel is shut down via Libvirt |
| Resume | Stopped unikernel is restarted |
| Destroy | Domain is undefined and all associated disks are removed |

Power behaviour:

- **On poweroff** — unikernel is destroyed
- **On reboot** — unikernel is restarted
- **On crash** — unikernel is destroyed

!!! note

    Unikernel nodes do not support the redeploy operation.
