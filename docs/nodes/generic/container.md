# Container

A generic container allows for the use of container models that are not natively defined within
Sherpa.

### Import

```
sherpa image import \
  --src container-registry/image \
  --version vX.Y.Z  \
  --model generic_container
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP Method           | Bind      |
| Management Interface | eth0      |
| Interface Driver     | virtio    |

## Example Manifest

```toml
name = "generic-container"

[[nodes]]
name = "dev01"
model = "generic_container"
image = "container-registry/image"
version = "vX.Y.Z"
commands = ["some", "start", "commands"]
```

## Notes
