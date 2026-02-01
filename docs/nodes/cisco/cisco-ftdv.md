# Cisco FTDv

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

## Import Image

```
sherpa image import \
  --src Cisco_Secure_Firewall_Threat_Defense_Virtual-7.7.0-89.qcow2 \
  --version 7.7.0-89 \
  --model cisco_ftdv \
  --latest
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 7.7.0-89        |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CDROM           |
| Management Interface | mgmt0/0         |
| Data Interfaces      | gig0/0-7        |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "cisco-ftdv"

nodes = [
  { name = "dev01", model = "cisco_ftdv" },
]
```

## Credentials

Creating a user and enabling SSH key based authentication is not supported via ZTP for this
platform.

The login credentials are:

| Username | Password       |
| -------- | -------------- |
| `admin`  | `Everest1953!` |

## Notes

- Approximate time for the system to be ready: `8 minutes`
