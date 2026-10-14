# Nanos Unikernel

[NanoVMs](https://nanovms.com/) unikernels are single-purpose machine images built with the Nanos unikernel framework. They boot via the DiskBoot mode, where the unikernel boots from a cloned disk image like a traditional VM.

## Building an Image

You need the [ops](https://ops.city) command, which builds Nanos images.

1. Install `ops`:

    ```bash
    curl https://ops.city/get.sh -sSfL | sh
    ```

2. Build an image from a package. For example, nginx:

    ```bash
    ops image create eyberg/nginx -i nanos-nginx
    ```

    List available packages with `ops pkg list`. The image is written to
    `~/.ops/images/nanos-nginx.img`.

3. Sherpa needs a QCOW2 file. If the image is raw, convert it:

    ```bash
    qemu-img convert -f raw -O qcow2 ~/.ops/images/nanos-nginx.img disk.qcow2
    ```

4. Check the result:

    ```bash
    qemu-img info disk.qcow2
    ```

5. Import it as described [below](#import-image), using the path to the file.

The application and its configuration are built into the disk image. Nanos does not use
`kernel_cmdline`.

## Import Image

```
sherpa server image import \
  --src <path-to-disk.qcow2> \
  --version <version> \
  --model nanos_unikernel
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Unikernel |
| CPU                  | 1         |
| RAM                  | 512 MiB   |
| Boot Mode            | DiskBoot  |
| ZTP Method           | None      |
| Management Interface | eth0      |
| Interface Driver     | virtio    |

## Example Manifest

```toml
name = "nanos-unikernel"

nodes = [
  { name = "dev01", model = "nanos_unikernel", version = "v1.0.0", ready_port = 8083 },
]
```

## Node Access

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Boot mode is `disk_boot` — the unikernel boots from a cloned QCOW2 disk image
- The base disk image is cloned into the lab directory at startup; the original is never modified

## Troubleshooting

**Image not found.** Scan the images directory, then list unikernel images:

```bash
sherpa server image scan --unikernel
sherpa server image list --unikernel
```

**Unikernel does not boot.**

- Check the server log with `journalctl -u sherpad`.
- Check the disk with `qemu-img check disk.qcow2`.
- Confirm the image was built for the QEMU/KVM platform, not Xen or VMware.

**No network.**

- Confirm the image supports virtio network devices.
- Unikernels get their address by DHCP. Check that the lab router is running.
