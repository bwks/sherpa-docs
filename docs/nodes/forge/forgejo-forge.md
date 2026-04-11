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

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Container       |
| CPU                  | 1               |
| RAM                  | 1GB             |
| ZTP Method           | None            |
| Management Interface | eth0            |
| Interface Driver     | macvlan         |

## Example Manifest

```toml
name = "forgejo-lab"

nodes = [
  { name = "forge01", model = "forgejo_forge", version = "11" },
]
```

## Notes

- Approximate time for the system to be ready: `1 minute`
