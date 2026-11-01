# Arista cEOS

Arista cEOS is a container based image.

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download).

!!! note

    An account is required, which can be created without any support contract.

Look for the 64 bit `cEOS Lab` image.

### Import image

The download is a root filesystem archive, so it is imported into Docker with
`docker image import`, tagged with the cEOS version, and then registered with Sherpa by scanning
the local container images:

```
docker image import cEOS64-lab-4.35.1F.tar.xz localrepo/arista_ceos:4.35.1F
sherpa server image scan --container
```

!!! warning

    Arista cEOS images must be imported with the repo set to `localrepo/arista_ceos`. The scan
    only registers images with that repo as the `arista_ceos` node model, and labs start cEOS
    from it. The first version registered becomes the default.

`sherpa server image import` does not work for cEOS: it loads `docker save` archives, not root
filesystem archives.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 2         |
| RAM                  | 4GB       |
| ZTP Method           | Volume    |
| Management Interface | eth0      |
| Data Interfaces      | eth1-52         |
| Interface Driver     | macvlan   |

## Example Manifest

```toml
name = "arista-ceos"

[[nodes]]
name = "dev01"
model = "arista_ceos"
version = "4.35.1F"
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
- The node boots from its ZTP configuration, copied to `flash:startup-config` the first time the
  container starts. `write memory` saves to it as usual (since Sherpa 0.4.16; before, it failed
  with `Device or resource busy`). The saved configuration is kept across `sherpa down` and
  `sherpa resume`. `sherpa redeploy` creates a new container, so it starts again from the ZTP
  configuration.
