# Cisco CAT9000v

## Base Image

See the [general notes](general.md) for information on obtaining a base image.

!!! Note

    The Catalyst 9000v is available in 2 variants: `q200` and `uadp`. This page refers to the `uadp` variant.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 17.15.03 \
  --model cisco_cat9000 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 17.15.03        |
| CPU                  | 4               |
| RAM                  | 18GB            |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP                  | `cdrom`         |
| Management Interface | GigabitEthernet0/0 |
| Data Interfaces      | gig0/0/1-8      |
| Interface Driver     | e1000           |

## Example Manifest

```toml
name = "cisco-cat9000"

[[nodes]]
name = "dev01"
model = "cisco_cat9000"
```


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Approximate time for the system to be ready: `4 minutes`
- Your login takes only your RSA keys of 4096 bits or less, the first 2 of them: IOS takes no
  other key type and no larger RSA key. `sherpa up` lists the keys it leaves out, and stops if
  none is left; make one with `ssh-keygen -t rsa -b 4096`. See
  [SSH Keys](../../architecture/ssh-keys.md#which-key-type).
- Sherpa is tested with the `UADP` image variant.
