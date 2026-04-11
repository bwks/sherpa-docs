# Red Hat Linux

## Base Image

Base images can be downloaded from the [Red Hat Enterprise Linux Downloads](https://access.redhat.com/downloads/content/rhel) page.

Look for the `KVM Guest` image with in the name.

!!! Note

    An account is required. Creating a free developer account allows you to access Red Hat Enterprise Linux images.

## Import Image

```
sherpa server image import \
  --src rhel-10.1-x86_64-kvm.qcow2 \
  --model redhat_linux \
  --version 10.1 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 10.1            |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "redhat-linux"

nodes = [
  { name = "dev01", model = "redhat_linux" },
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

- Approximate time for the system to be ready: `1 minute`
