# Container

A generic container allows for the use of container models that are not natively defined within
Sherpa.

### Import

#### Sherpa

Pull the image down via sherpa

```
sherpa container image pull nginx:1.29.4-perl
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull nginx:1.29.4-perl
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP Method           | Volume    |
| Management Interface | eth0      |
| Interface Driver     | virtio    |

## Example Manifest

```toml
name = "generic-container"

nodes = [
  { name = "dev01", model = "generic_container", image = "nginx", version = "1.29.4-perl" },
]
```

## Notes
