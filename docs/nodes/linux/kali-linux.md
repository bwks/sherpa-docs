# Kali Linux

## Base Image

Base images can be downloaded from [Kali Cloud Images](https://www.kali.org/get-kali/#kali-cloud).

## Extract image
```
tar -xvf kali-linux-2026.1-cloud-genericcloud-amd64.tar.xz
```

## Convert image
```
sudo virt-sparsify --format raw disk.raw --convert qcow2 kali.qcow2
```

## Import Image

```
sherpa server image import \
  --src kali.qcow2 \
  --model kali_linux \
  --version 2026.1 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 2026.1           |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "kali-linux"

nodes = [
  { name = "dev01", model = "kali_linux" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
