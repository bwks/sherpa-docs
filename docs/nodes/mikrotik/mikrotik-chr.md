# Mikrotik CHR

## Base Image

A base image that is compatible with Sherpa can be built
using [this](https://github.com/bwks/packer-mikrotik) Packer template.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model mikrotik_chr \
  --version 7.20.8 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 7.20.8          |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | IDE             |
| ZTP                  | `disk`          |
| Management Interface | ether1          |
| Data Interfaces      | eth1-8          |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

[[nodes]]
name = "dev01"
model = "mikrotik_chr"
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
- The config disk carries the node's `config.rsc` and one file per SSH key of yours. The image's
  `sherpa-ztp` scheduler imports `config.rsc` once a minute until an import completes. Its
  `sherpa-ssh-key` scheduler imported the lab SSH key that Sherpa before 0.7.0 put on the disk;
  with no such file it does nothing, and an image build can leave it out.
