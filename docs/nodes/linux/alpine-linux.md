# Alpine Linux

## Base Image

Base images can be downloaded from [Alpine Cloud Images](https://alpinelinux.org/cloud/).

Look for the `No Cloud` image with `cloud-init` enabled.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model alpine_linux \
  --version 3.23.0 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 3.23.0          |
| Kind                 | Virtual Machine |
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
name = "alpine-linux"

[[nodes]]
name = "dev01"
model = "alpine_linux"
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
- Alpine keeps its native tools: the `ash` shell (`/bin/sh`) and `doas`. Bash and `sudo` are
  not installed, including for [personal accounts](../../architecture/personal-accounts.md).
  Start `startup_scripts` and `user_scripts` with `#!/bin/sh`, or install Bash first.
