# Cisco CSR1000v

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src csr1000v-universalk9.17.03.08a-serial.qcow2 \
  --version 17.03.08a \
  --model cisco_csr1000v \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 17.03.08a       |
| CPU                  | 1               |
| RAM                  | 3GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CDROM           |
| Management Interface | gig1            |
| Data Interfaces      | gig2-16         |
| Interface Driver     | vmxnet3         |

## Example Manifest

```toml
name = "cisco-csr1000v"

nodes = [
  { name = "dev01", model = "cisco_csr1000v" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `3 minutes`
