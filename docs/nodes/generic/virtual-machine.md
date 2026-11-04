# Virtual Machine

A generic virtual machine allows for VM models that are not natively defined within Sherpa.

### Import

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
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
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | Cloud-Init      |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

The image must run `cloud-init` with the NoCloud data source, like a Linux cloud image. Sherpa
sets it up as a Linux VM: the `sherpa` user with passwordless `sudo`, the management address,
and your [personal account](../../architecture/personal-accounts.md) when
`provision_current_user` is set. For an image without `cloud-init`, turn off ZTP on the image's
edit page in the web UI (**Admin > Images**), so it boots without ZTP.

## Example Manifest

```toml
name = "generic-vm"

[[nodes]]
name = "dev01"
model = "generic_vm"
version = "model-version"
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
