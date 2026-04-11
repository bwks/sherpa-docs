# Virtual Machine

A generic virtual machine allows for VM models that are not natively defined within Sherpa.

### Import

```
sherpa server image import \
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
| RAM                  | 1GB             |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | Cloud-Init      |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "generic-vm"

nodes = [
  { name = "dev01", model = "generic_vm", version = "model-version" },
]
```


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes
