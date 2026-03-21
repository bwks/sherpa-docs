# PostgreSQL

PostgreSQL is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/_/postgres).

### Import image

#### Sherpa

```
sherpa server image pull postgres:17
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull postgres:17
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP Method           | Volume    |
| Management Interface | eth0      |
| Interface Driver     | macvlan    |

## Example Manifest

```toml
name = "postgresql"

nodes = [
  { name = "db01", model = "postgresql", version = "17" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
