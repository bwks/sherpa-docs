# SUSE Linux

## Base Image

Base images can be downloaded from the [SUSE Linux Enterprise Downloads](https://www.suse.com/download/sles/) page.
Look for the `qcow2` image with `cloud` in the name.
An account is required, which can be created without any support contract.

## Import Image

```
sherpa image import \
  --src SLES15-SP7-Minimal-VM.x86_64-Cloud-GM.qcow2 \
  --model suse_linux \
  --version 15.SP7 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 15.SP7          |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "suse-linux"

nodes = [
  { name = "dev01", model = "suse_linux" },
]
```

## Notes

- Approximate boot time to interactive: `1 minute`
