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

An image already pulled with the `docker` CLI is not known to Sherpa until it is scanned. The
scan records each local tag of `nats` as a version:

```
docker pull nats:2.11
sherpa server image scan --container
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Container       |
| CPU                  | 1               |
| RAM                  | 512MB           |
| ZTP                  | `disabled`      |
| Management Interface | eth0            |
| Data Interfaces      | eth1+           |
| Interface Driver     | macvlan         |

## Example Manifest

```toml
name = "nats-lab"

[[nodes]]
name = "nats01"
model = "nats_bus"
version = "2.10"
```


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Docker"

    ```
    docker exec -it <node-name>-<lab-id> sh
    ```

## Notes

- Approximate time for the system to be ready: `30 seconds`
