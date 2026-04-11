# Paloalto PA-VM

Paloalto PA-VM is a virtual machine based image.

## Base Image

Base images can be downloaded from the Paloalto support portal.

!!! note

    An account with a valid support contract is required to download VM images.

### Import

```
sherpa server image import \
  --src PA-VM-KVM-11.1.6-h7.qcow2 \
  --version 11.1.6-h7  \
  --model paloalto_panos
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 8GB             |
| CDROM Driver         | sata          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CDROM      |
| Management Interface | management            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "paloalto_panos"

nodes = [
  { name = "dev01", model = "paloalto_panos" },
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

- Approximate time for the system to be ready: `8 minutes`