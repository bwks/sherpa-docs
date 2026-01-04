# NanoVM

A generic nanovm allows for the use of nanovm models that are not natively defined within
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
name = "generic-nanovm"

nodes = [
  { name = "dev01", model = "generic_nanovm", repo = "nanovm-registry/image", version = "vX.Y.Z" },
]
```

## Notes

f
