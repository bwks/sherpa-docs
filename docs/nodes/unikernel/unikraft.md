# Unikraft Unikernel

[Unikraft](https://unikraft.org/) unikernels are lightweight, single-purpose machine images built with the Unikraft framework. They boot via the DirectKernel mode, where QEMU loads the kernel ELF binary directly.

## Building an Image

You need [kraftkit](https://github.com/unikraft/kraftkit) (the `kraft` command) and Docker.

1. Create an application, or use one from the [Unikraft catalog](https://github.com/unikraft/catalog):

    ```bash
    kraft init -t nginx@1.15 my-nginx
    cd my-nginx
    ```

2. Build it for QEMU:

    ```bash
    kraft build --plat qemu --arch x86_64
    ```

3. Find the kernel file. Its name varies by application:

    ```bash
    find .unikraft/build -name "*.elf" -o -name "*_qemu-x86_64"
    ```

4. Check that it is a 64-bit x86 ELF executable:

    ```bash
    file <path-to-elf>
    ```

5. Import it as described [below](#import-image), using the path to the file.

## Import Image

```
sherpa server image import \
  --src <path-to-kernel.elf> \
  --version <version> \
  --model unikraft_unikernel
```

## Default Node Parameters

| Property             | Value        |
| -------------------- | ------------ |
| Kind                 | Unikernel    |
| CPU                  | 1            |
| RAM                  | 512 MiB      |
| Boot Mode            | DirectKernel |
| ZTP Method           | None         |
| Management Interface | eth0         |
| Interface Driver     | virtio       |

## Example Manifest

```toml
name = "unikraft-unikernel"

nodes = [
  { name = "dev01", model = "unikraft_unikernel", version = "v1.0.0", kernel_cmdline = "/usr/bin/nginx", ready_port = 80 },
]
```

## Node Access

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Boot mode is `direct_kernel` — the kernel ELF binary is loaded directly by QEMU
- Use `kernel_cmdline` to specify the application entry point or pass runtime arguments to the unikernel
- Use `ready_port` to have Sherpa wait for a TCP port to become available before marking the node as ready
- Uses DHCP for IP assignment with static MAC-based binding on the management router

## Troubleshooting

**Image not found.** Scan the images directory, then list unikernel images:

```bash
sherpa server image scan --unikernel
sherpa server image list --unikernel
```

**Unikernel does not boot.**

- Check the server log with `journalctl -u sherpad`.
- Confirm the file is an x86-64 ELF with `file`.
- Confirm the image was built for the QEMU/KVM platform, not Xen or VMware.

**No network.**

- Confirm the image was built with network support and a virtio network driver.
- Unikernels get their address by DHCP. Check that the lab router is running.
