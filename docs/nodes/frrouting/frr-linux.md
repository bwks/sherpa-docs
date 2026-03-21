# FRR Linux

FRRouting Linux is a container based image.

## Base Image

Base images can be obtained from the [FRRouting](https://quay.io/repository/frrouting/frr)
container registry.

### Import image

#### Sherpa

```
sherpa server image pull -m frr_linux -v 10.5.2 
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull quay.io/frrouting/frr:10.5.2
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 512MB       |
| ZTP Method           | Volume    |
| Management Interface | eth0      |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "frr-linux"

nodes = [
  { name = "dev01", model = "frr_linux", version = "10.5.2" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
