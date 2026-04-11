# NATS

NATS is a high-performance messaging system, running as a container node.

## Base Image

Container images are pulled from [Docker Hub](https://hub.docker.com/_/nats).

## Import Image

```
sherpa server image pull \
  --model nats_bus \
  --repo nats:<tag> \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Container       |
| CPU                  | 1               |
| RAM                  | 512MB           |
| ZTP Method           | None            |
| Management Interface | eth0            |
| Data Interfaces      | eth1+           |
| Interface Driver     | macvlan         |

## Example Manifest

```toml
name = "nats-lab"

nodes = [
  { name = "nats01", model = "nats_bus", version = "2.10" },
]
```

## Notes

- Approximate time for the system to be ready: `30 seconds`
