# Virtual Machine

A generic virtual machine allows for VM models that are not natively defined within Sherpa.

### Import

```
sherpa image import \
  --src filename.qcow2 \
  --version model-version  \
  --model generic_vm
```

!!! note

    The `--latest` parameter is ignored for the `generic_vm` model.

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 2GB             |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CloudInit       |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "generic-vm"

nodes = [
  { name = "dev01", model = "generic_vm", version = "model-version" },
]
```

## Notes
