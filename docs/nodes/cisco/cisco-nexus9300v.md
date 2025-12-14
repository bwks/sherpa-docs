# Cisco Nexus 9300v

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src nexus9300v64.10.5.3.F.qcow2 \
  --version 10.5.3.F \
  --model cisco_nexus9300v \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 10.5.3.F        |
| CPU                  | 2               |
| RAM                  | 12GB            |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | CDROM           |
| Management Interface | mgmt0           |
| Data Interfaces      | eth1-64         |
| Interface Driver     | e1000           |

## Example Manifest

```toml
name = "cisco-nexus9300v"

nodes = [
  { name = "dev01", model = "cisco_nexus9300v" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `5 minutes`
