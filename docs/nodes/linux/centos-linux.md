# CentOS Linux

## Base Image

Base images can be downloaded from the [CentOS Stream](https://www.centos.org/download/) page.

Look for the Generic Cloud image, for example
`CentOS-Stream-GenericCloud-10-20261021.0.x86_64.qcow2` from
<https://cloud.centos.org/centos/10-stream/x86_64/images/>. Check it against the matching
`.SHA256SUM` file with `sha256sum -c`.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model centos_linux \
  --version 10-20261021.0 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 10-20261021.0   |
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
name = "centos-linux"

[[nodes]]
name = "dev01"
model = "centos_linux"
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
