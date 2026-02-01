# Arista cEOS

Arista cEOS is a container based image.

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download).

!!! note

    An account is required, which can be created without any support contract.

Look for the 64 bit `cEOS Lab` image.

### Import image

The downloaded image must be imported with the `docker image import` command.

```
docker image import cEOS64-lab-4.35.1F.tar.xz arista/ceos:4.35.1F
```

!!! warning

    Arista cEOS images must be imported with the repo set to: `arista/ceos`.
    This allows for the definition of `arista_ceos` as a node model in the manifest file.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 2         |
| RAM                  | 2GB       |
| ZTP Method           | Volume    |
| Management Interface | Mgmt0     |
| Interface Driver     | virtio    |

## Example Manifest

```toml
name = "arista-ceos"

nodes = [
  { name = "dev01", model = "arista_ceos", version = "4.35.1F" },
]
```

## Node Access

=== "SSH"

    ```
    sherpa ssh dev01
    ```

=== "Console"

    ```
    sherpa console dev01
    ```

=== "Docker"

    ```
    docker exec -it dev01-<lab-id> sudo Cli
    ```

## Notes

- Approximate time for the system to be ready: `1 minutes`
