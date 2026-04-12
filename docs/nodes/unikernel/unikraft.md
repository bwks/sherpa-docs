# Unikraft Unikernel

[Unikraft](https://unikraft.org/) unikernels are lightweight, single-purpose machine images built with the Unikraft framework. They boot via the DirectKernel mode, where QEMU loads the kernel ELF binary directly.

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
  { name = "dev01", model = "unikraft_unikernel", version = "v1.0.0" },
]
```

## Node Access

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Boot mode is `direct_kernel` — the kernel ELF binary is loaded directly by QEMU
- Uses DHCP for IP assignment with static MAC-based binding on the management router
