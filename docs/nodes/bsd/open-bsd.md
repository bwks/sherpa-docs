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
| ZTP                  | `cloud-init`    |
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
- Admin rights use `doas`, part of OpenBSD's base system. [Your account](../../architecture/personal-accounts.md) is in `wheel`, and
  `/etc/doas.conf` lets `wheel` run commands as root without a password
  (`permit nopass keepenv :wheel`). No `sudo` rule is set up.
- OpenBSD's password hashing takes only bcrypt, so Sherpa gives cloud-init your
  [device password](../../architecture/device-password.md) as plain text and cloud-init hashes it
  on the node. Login names are at most 31 characters.

!!! Warning

    On a heavily loaded server, or with the default 1 CPU and 1 GB, an OpenBSD node can boot
    with no login. The images from [BSD Cloud Images](https://bsd-cloud-image.org/) start
    cloud-init's four stages (`cloudinitlocal`, `cloudinit`, `cloudconfig` and `cloudfinal`) from
    `/etc/rc.d` as rc daemons. rc waits at most `daemon_timeout` (30 seconds) for each one, then
    starts the next even if the previous one is still running. On a slow boot the stages overlap,
    and the `init` stage fails (`PermissionError` on `/var/lib/cloud/instance`) before it creates
    your user.

    To recover, redeploy the node, or give it more CPU and memory in the manifest:

    ```toml
    [[nodes]]
    name = "dev01"
    model = "open_bsd"
    memory = 2048

    [nodes.cpu]
    count = 2
    ```

    The fix belongs in the image. rc honours a per-daemon timeout, so setting
    `cloudinitlocal_timeout`, `cloudinit_timeout`, `cloudconfig_timeout` and `cloudfinal_timeout`
    (for example to `600`) in the image's `/etc/rc.conf.local` lets each stage finish before the
    next starts. If you build or customise your own image, add these there.
