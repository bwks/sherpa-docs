# Forgejo

Forgejo is a self-hosted Git forge, running as a container node.

## Base Image

Container images are pulled from the [Forgejo container registry](https://codeberg.org/forgejo/forgejo).

## Import Image

```
sherpa server image pull \
  --model forgejo_forge \
  --repo codeberg.org/forgejo/forgejo:<tag> \
  --default
```

An image already pulled with the `docker` CLI is not known to Sherpa until it is scanned. The
scan records each local tag of `codeberg.org/forgejo/forgejo` as a version:

```
docker pull codeberg.org/forgejo/forgejo:<tag>
sherpa server image scan --container
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Container       |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `disabled`      |
| Management Interface | eth0            |
| Interface Driver     | macvlan         |

## Example Manifest

```toml
name = "forgejo-lab"

[[nodes]]
name = "forge01"
model = "forgejo_forge"
version = "11"
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

- Approximate time for the system to be ready: `1 minute`
