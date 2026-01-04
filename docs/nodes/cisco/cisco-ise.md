# Cisco ISE

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

If you have a CML subscription, the `qcow2` image can also be found in the ref-platform ISO.

## Import Image

### Download

Base images can also be downloaded from the [Cisco Software](https://software.cisco.com/download/home) page.

Search for `Identity Services Engine Software` and download the `eval` image.

### Convert

!!! note

    This step is not required for the CML ref-platform image.

The image downloaded from [Cisco Software](https://software.cisco.com/download/home) is in `ova` format
and needs to be converted to `qcow2`.

```
mkdir ise-ova && \
  tar -xvf Cisco-vISE-300-3.5.0.527.ova -C ise-ova && \
  cd ise-ova && \
  qemu-img convert -p -f vmdk -O qcow2 Cisco-vISE-300-3.5.0.527-disk1.vmdk Cisco-vISE-300-3.5.0.527.qcow2
```

### Import

```
sherpa image import \
  --src Cisco-vISE-300-3.5.0.527.qcow2 \
  --version 3.5.0 \
  --model cisco_ise \
  --latest
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 3.5.0           |
| CPU                  | 16              |
| RAM                  | 32GB            |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | Disk            |
| Management Interface | eth0            |
| Data Interfaces      | eth1-4          |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "cisco-ise"

nodes = [
  { name = "dev01", model = "cisco_ise" },
]
```

## Logging

### Install

ISE Install progress logs can be viewed with the command:

```
show logging system ade/ADE.log tail
```

## Notes

- Approximate time for the system to be ready: `80 minutes`
- SSH key authentication is disabled by default, use [password](/architecture/credentials) auth instead.
