# Nanos Unikernel

[NanoVMs](https://nanovms.com/) unikernels are single-purpose machine images built with the Nanos unikernel framework. They boot via the DiskBoot mode, where the unikernel boots from a cloned disk image like a traditional VM.

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
