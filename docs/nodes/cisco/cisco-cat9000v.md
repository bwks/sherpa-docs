# Cisco CAT9000v

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

!!! Note

    The Catalyst 9000v is available in 2 variants: `q200` and `uadp`. This page refers to the `uadp` variant.

## Import Image

```
sherpa image import \
  --src cat9kv_prd.17.15.03.qcow2 \
  --version 17.15.03 \
  --model cisco_cat9000v \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 17.15.03        |
| CPU                  | 4               |
| RAM                  | 18GB            |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP Method           | CDROM           |
| Management Interface | gig0/0          |
| Data Interfaces      | gig0/0/1-8      |
| Interface Driver     | e1000           |

## Example Manifest

```toml
name = "cisco-cat8000v"

nodes = [
  { name = "dev01", model = "cisco_cat9000v" },
]
```

## Notes

- Approximate boot time and for ZTP to complete: `4 minutes`
- Sherpa is tested with the `UADP` image variant.
