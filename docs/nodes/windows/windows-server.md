# Windows Server

## Base Image

Microsoft does not provide ready built qcow2 images so you will need to build them yourself.
You can use [this](https://github.com/bwks/packer-windows) packer template to build windows
images with cloudbase-init and an SSH server enabled. 

Currently, only Windows Server 2022 is supported, but more versions are coming soon.

## Import

```
sherpa server image import \
  --src windows_server_2022-20260307.qcow2 \
  --version 2022-20260307 \
  --model windows_server \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 2022-20260307     |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

nodes = [
  { name = "dev01", model = "windows_server" },
]
```

## Notes

- Approximate time for the system to be ready: `3 minutes`
