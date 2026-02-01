# Windows Server

## Base Image

A Windows Server version 2012 with cloudbase-init can be downloaded from
the makers of cloud-init for Windows [cloudbase.it](https://cloudbase.it).

Download the `kvm` image from the Products [download page](https://cloudbase.it/windows-cloud-images/).

## Import

### Extract

```
 gunzip windows_server_2012_r2_standard_eval_kvm_20170321.qcow2.gz
```

### Import Image

```
sherpa image import \
  --src windows_server_2012_r2_standard_eval_kvm_20170321.qcow2 \
  --version 2012-0.9.11 \
  --model windows_server \
  --latest
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 2012-0.9.11     |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | Cloud-init      |
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

- Approximate time for the system to be ready: `1 minute`
