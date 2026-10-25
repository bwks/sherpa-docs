# Open BSD

## Base Image

Base images can be downloaded from [BSD Cloud Images](https://bsd-cloud-image.org/).

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model open_bsd \
  --version 7.8 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 7.8             |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "open-bsd"

[[nodes]]
name = "dev01"
model = "open_bsd"
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

- Approximate time for the system to be ready: `1 minute`
- IPv4 only. The node is allocated an IPv6 management address, but it is not configured on the
  node. cloud-init's OpenBSD network renderer does not configure IPv6 addresses, and it fails
  on an IPv6 default route, which would leave the node with no network. Sherpa therefore sends
  OpenBSD nodes IPv4 settings only.
- Admin rights use `doas`, part of OpenBSD's base system. The `sherpa` user and your
  [personal account](../../architecture/personal-accounts.md) are in `wheel`, and
  `/etc/doas.conf` lets `wheel` run commands as root without a password
  (`permit nopass keepenv :wheel`). No `sudo` rule is set up.
