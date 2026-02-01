# Unikernel

A generic unikernel allows for the use of unikernel models that are not natively defined within
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
name = "generic-unikernel"

nodes = [
  { name = "dev01", model = "generic_unikernel", repo = "unikernel-registry/image", version = "vX.Y.Z" },
]
```

## Notes

f
