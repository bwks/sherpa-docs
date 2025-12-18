# Mikrotik CHR

## Base Image

Download the `RAW disk` image from the [Mikrotik downloads](https://mikrotik.com/download/chr) page.

## Import Image

### Unzip the download

```
unzip chr-7.20.6.img.zip
```

### Import

```
sherpa image import \
  --src chr-7.20.6.img \
  --model mikrotik_chr \
  --version 7.20.6 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 7.20.6          |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 2GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth1            |
| Data Interfaces      | eth1-8          |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

nodes = [
  { name = "dev01", model = "mikrotik_chr" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
