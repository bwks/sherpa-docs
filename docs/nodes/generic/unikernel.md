# Unikernel

A generic unikernel allows for the use of unikernel models that are not natively defined within
Sherpa.

## Import Image

```
sherpa server image import \
  --src <path-to-image> \
  --version <version> \
  --model generic_unikernel
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
name = "generic-unikernel"

nodes = [
  { name = "dev01", model = "generic_unikernel", version = "v1.0.0", kernel_cmdline = "/usr/bin/nginx", ready_port = 80 },
]
```

## Node Access

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Boot mode is `direct_kernel` by default — the kernel ELF binary is loaded directly by QEMU
- Use `kernel_cmdline` to specify the application entry point or pass runtime arguments to the unikernel
- Use `ready_port` to have Sherpa wait for a TCP port to become available before marking the node as ready
- ZTP is disabled by default; configure it in the manifest if needed
