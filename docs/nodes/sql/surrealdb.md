# SurrealDB

SurrealDB is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/r/surrealdb/surrealdb).

### Import image

#### Sherpa

```
sherpa server image pull surrealdb/surrealdb:v2.2
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull surrealdb/surrealdb:v2.2
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
name = "surrealdb"

nodes = [
  { name = "db01", model = "surrealdb", version = "v2.2" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
