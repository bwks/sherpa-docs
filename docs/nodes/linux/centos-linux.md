# CentOS Linux

## Base Image

Base images can be downloaded from the [CentOS Stream](https://www.centos.org/download/) page.

Look for the Generic Cloud image.

## Import Image

```
sherpa server image import \
  --src CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2 \
  --model centos_linux \
  --version 10-20260401 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 10-20260401     |
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

nodes = [
  { name = "dev01", model = "centos_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
