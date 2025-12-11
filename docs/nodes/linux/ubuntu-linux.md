## Base Image

Base images can be downloaded from [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/).

## Import Image

```
sherpa image import \
  --src noble-server-cloudimg-amd64.img \
  --model ubuntu_linux \
  --version 24.04 \
  --latest
```

## Node Parameters

| Property             | Value        |
| -------------------- | ------------ |
| Tested Version       | 24.04        |
| CPU                  | 1            |
| RAM                  | 1GB          |
| CDROM Driver         | SATA         |
| DISK                 | virtio.qcow2 |
| DISK Driver          | virtio       |
| ZTP Method           | cloud-init   |
| Management Interface | eth1         |
| Interface Driver     | virtio       |

## Example Manifest

```toml
name = "silly-sausage"

nodes = [
  { name = "dev01", model = "ubuntu_linux" },
]
```

## Notes

- Approximate boot time to interactive: `1 minute`
