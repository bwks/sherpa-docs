# Arista cEOS

Arista cEOS is a container based image.

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download).

!!! note

    An account is required, which can be created without any support contract.

Look for the 64 bit `cEOS Lab` image.

### Import image

```
docker image import cEOS64-lab-4.35.1F.tar.xz arista-ceos:4.35.1F
```

TODO: Update to use shepra CLI for import.

```
sherpa image import \
  --src cEOS64-lab-4.35.1F.tar.xz \
  --version 4.35.1F \
  --model arista_ceos \
  --latest
```

## Default Node Parameters

| Property             | Value         |
| -------------------- | ------------- |
| Kind                 | Container     |
| Tested Version       | 4.35.1F       |
| CPU                  | 2             |
| RAM                  | 2GB           |
| CDROM                | aboot.iso     |
| CDROM Driver         | IDE           |
| DISK                 | virtioa.qcow2 |
| DISK Driver          | SATA          |
| ZTP Method           | TFTP          |
| Management Interface | mgmt1         |
| Data Interfaces      | eth1-52       |
| Interface Driver     | virtio        |

## Example Manifest

```toml
name = "arista-ceos"

nodes = [
  { name = "dev01", model = "arista_ceos" },
]
```

## Notes

- Approximate time for the system to be ready: `3 minutes`
