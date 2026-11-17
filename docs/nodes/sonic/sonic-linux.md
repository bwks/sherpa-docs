# Sonic Linux

## Base Image

Base images can be downloaded from [TBC]().

!!! Warning

    Virtual Machine images from [sonic.software](https://sonic.software/) do not have ZTP enabled
    during compilation. If you obtain your image from there, ZTP will not work.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model sonic_linux \
  --version 20251215 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 20251215        |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `http`          |
| Management Interface | eth0            |
| Data Interfaces      | eth1-32         |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "sonic-linux"

[[nodes]]
name = "dev01"
model = "sonic_linux"
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

## Front-panel Ports

The VM has 32 front-panel ports, `Ethernet0` to `Ethernet124`. Data interface `ethN` is port
`Ethernet(4 × (N − 1))`: `eth1` is `Ethernet0`, `eth2` is `Ethernet4` and `eth32` is `Ethernet124`.

Sherpa's ZTP brings all 32 ports up administratively (`admin_status` up), linked or not, and
saves the result to `/etc/sonic/config_db.json`, so the ports stay up after a reboot.

## Notes

- Approximate time for the system to be ready: `2 minutes`
